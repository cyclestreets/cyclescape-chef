#
# Cookbook Name:: cyclescape
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

include_recipe 'apt'
include_recipe 'ssl'
include_recipe 'apache2'
include_recipe 'postgres'
include_recipe 'ntp'
include_recipe 'rbenv'
include_recipe 'passenger-gem'
include_recipe 'postfix'
include_recipe 'cyclescape-user'
include_recipe 'cyclescape-backups'
include_recipe 'ufw::recipes'
include_recipe 'munin-plugins-rails'

# Geos dev package for RGeo gem
package 'libgeos-dev'

if node['platform'] == 'ubuntu' && node['platform_version'] == '14.04'
  ['/usr/lib/libgeos.so', '/usr/lib/libgeos.so.1'].each do |t|
    link t do
      to '/usr/lib/libgeos-3.4.2.so'
    end
  end
end

# Redis server for queueing and caching
package 'redis-server'

# Imagemagick, for dragonfly to do image processing with convert
package 'imagemagick'

# mailx - not actually for the app, just for some other scripts we have
package 'heirloom-mailx'

# git - useful when running testing the scripts with Vagrant. Normally
# installed manually in order to acquire the cookbooks, as per README
package 'git'

apache_module 'rewrite'
if node['platform'] == 'ubuntu' && node['platform_version'] == '14.04'
  apache_module 'socache_shmcb'
end
apache_module 'ssl'
apache_module 'expires'
apache_module 'headers'

# We can install bundler with the ubuntu version of gem ...
gem_package 'bundler' do
  gem_binary '/usr/bin/gem1.9.1'
  action :install
end

# ... but it installs binaries into a non-PATH directory
# See http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=448639
link '/usr/bin/bundle' do
  to '/var/lib/gems/1.9.1/bin/bundle'
end

# Install a very old version of nodejs
package 'nodejs'

# Create the database user. For now, it's a superuser.
script 'create cyclescape db user' do
  interpreter 'bash'
  user 'postgres'
  group 'postgres'
  cwd '/var/lib/postgresql'
  code <<-EOH
    createuser cyclescape -s
  EOH
  not_if %q(test -n "`sudo -u postgres psql template1 -A -t -c '\du cyclescape'`") # Mmm, hacky
end

deploy_dir = '/var/www/cyclescape'
shared_dir = File.join(deploy_dir, 'shared')

[deploy_dir, shared_dir, File.join(shared_dir, 'config'), File.join(shared_dir, 'log'),
 File.join(shared_dir, 'system'), File.join(shared_dir, 'tmp/dragonfly'),
 File.join(shared_dir, 'tmp/index')].each do |dir|
  directory dir do
    owner 'cyclescape'
    group 'cyclescape'
    recursive true
  end
end

template deploy_dir + '/shared/config/database.yml' do
  source 'database.example.yml'
  owner 'cyclescape'
  group 'cyclescape'
  mode '0644'
  variables script_dir: node['postgres']['script_dir']
end

mb = data_bag_item('secrets', 'mailbox')

template deploy_dir + '/shared/config/mailboxes.yml' do
  source 'mailboxes.example.yml'
  owner 'cyclescape'
  group 'cyclescape'
  mode '0400'
  variables(
    server: mb['server'],
    username: mb['username'],
    password: mb['password']
  )
end

deploy_revision deploy_dir do
  repo 'https://github.com/cyclestreets/cyclescape.git'
  revision 'master'
  user 'cyclescape'
  group 'cyclescape'
  before_migrate do
    current_release_directory = release_path
    shared_directory = new_resource.shared_path
    running_deploy_user = new_resource.user
    bundler_depot = new_resource.shared_path + '/bundle'
    shared_config = new_resource.shared_path + '/config'
    excluded_groups = %w(development test)

    # This must be called before any bundle execs
    script 'Bundling the gems' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      environment 'LC_ALL' => 'en_GB.UTF-8'
      code <<-EOS
        bundle install --quiet --deployment --path #{bundler_depot} \
        --without #{excluded_groups.join(' ')}
      EOS
    end

    # Stop any cron jobs from running during migration
    script 'Clear crontab' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      code <<-EOH
        bundle exec whenever --clear-crontab cyclescape_app
      EOH
    end

    # The symlink_before_default does this, but annoyingly comes after before_migrate is called
    # That way, db:create fails. So do it manually instead...
    link current_release_directory + '/config/database.yml' do
      to shared_config + '/database.yml'
    end

    link current_release_directory + '/config/mailboxes.yml' do
      to shared_config + '/mailboxes.yml'
    end

    # Things for the dragonfly gem
    directory current_release_directory + '/tmp' do
      action :create
      owner 'cyclescape'
      group 'cyclescape'
    end

    link current_release_directory + '/tmp/dragonfly' do
      to shared_directory + '/tmp/dragonfly'
    end

    # acts-as-indexed gem
    link current_release_directory + '/tmp/index' do
      to shared_directory + '/tmp/index'
    end

    script 'Create the database' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => 'production'
      code <<-EOH
        bundle exec rake db:create
      EOH
      not_if %q(test -n "`sudo -u postgres psql template1 -A -t -c '\l' | grep cyclescape_production`")
    end

    script 'Compile the assets' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => 'production'
      code <<-EOH
        bundle exec rake assets:precompile
      EOH
    end

    # We need to create a secret token, and store it in the shared config
    # path for future use.
    script 'create the secret token' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      code "bundle exec rake secret > #{shared_config + '/secret_token'}"
      not_if "test -e #{shared_config + '/secret_token'}"
    end

    link current_release_directory + '/config/secret_token' do
      to shared_config + '/secret_token'
    end
  end

  before_restart do
    script 'Update seed data' do
      interpreter 'bash'
      cwd release_path
      user new_resource.user
      environment 'RAILS_ENV' => 'production'
      code <<-EOH
        bundle exec rake db:seed
      EOH
    end

    # use foreman to create upstart files.
    script 'Update foreman configuration' do
      interpreter 'bash'
      cwd release_path
      code <<-EOH
        bundle exec foreman export upstart /etc/init -a cyclescape -u cyclescape -e .env.production
      EOH
      notifies :restart, 'service[cyclescape]'
    end

    service 'cyclescape' do
      provider Chef::Provider::Service::Upstart
      supports restart: true
    end

    script 'Set crontab' do
      interpreter 'bash'
      cwd release_path
      user new_resource.user
      code <<-EOH
        bundle exec whenever -i cyclescape_app --update-crontab
      EOH
    end
  end

  migrate true
  migration_command 'bundle exec rake db:migrate'
  environment 'RAILS_ENV' => 'production'
  action :deploy
  restart_command 'touch tmp/restart.txt'
end

# sort out the virtual hosts, with delayed reloading of apache2
link '/etc/apache2/sites-enabled/000-default' do
  action :delete
  only_if 'test -L /etc/apache2/sites-enabled/000-default'
  notifies :reload, 'service[apache2]'
end

template '/etc/apache2/sites-available/cyclescape.conf' do
  source 'passenger.vhost.conf'
  owner 'www-data'
  group 'www-data'
  mode '0644'
  notifies :reload, 'service[apache2]'
end

link '/etc/apache2/sites-enabled/cyclescape.conf' do
  to '/etc/apache2/sites-available/cyclescape.conf'
  notifies :reload, 'service[apache2]'
end

# Enable ExtendedStatus in apache2
# This can be removed with later apache2 versions which have it included by default.
apache_conf 'status'
