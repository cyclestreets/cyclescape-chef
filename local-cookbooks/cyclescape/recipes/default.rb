#
# Cookbook Name:: cyclescape
# Recipe:: default
#
# Copyright 2015, Cyclestreets Ltd

ENV["PATH"] = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
include_recipe 'apt'
include_recipe 'ssl'
include_recipe 'apache2'
include_recipe 'postgres'
include_recipe 'ntp'
include_recipe 'java'
include_recipe 'brightbox-ruby::default'
gem_package 'rack' do
  action :install
  version "1.6.0"
end
include_recipe 'passenger_apache2'
include_recipe 'postfix'
include_recipe 'cyclescape-user'
include_recipe 'cyclescape-backups'
include_recipe 'ufw'
include_recipe 'munin-plugins-rails'
include_recipe 'nodejs::npm'

deploy_dir = '/var/www/cyclescape'
shared_dir = File.join(deploy_dir, 'shared')
node.default['letsencrypt']['error_email'] = data_bag_item("secrets", "i18n")["error_email"]
node.default['letsencrypt']['domain_names'] = [data_bag_item('secrets', 'dns')["domain_name"]]
node.default['letsencrypt']['domain_names_and_passwords'] = [data_bag_item('secrets', 'dns')["domain_name"] => data_bag_item('secrets', 'dns')["dns_api_password"]]
node.default['letsencrypt']['working_dir'] = shared_dir

include_recipe 'letsencrypt'

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
  action :install
  version "1.16.0"
end

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

[
  deploy_dir, shared_dir,
  File.join(shared_dir, 'config'), File.join(shared_dir, 'log'),
  File.join(shared_dir, 'system'), File.join(shared_dir, 'tmp', 'dragonfly'),
].each do |dir|
  directory dir do
    owner 'cyclescape'
    group 'cyclescape'
    recursive true
  end
end

template deploy_dir + '/shared/config/database.yml' do
  source 'database.yml.erb'
  owner 'cyclescape'
  group 'cyclescape'
  mode '0644'
  variables script_dir: node['postgres']['script_dir']
end

mb = data_bag_item('secrets', 'mailbox')

template deploy_dir + '/shared/config/mailboxes.yml' do
  source 'mailboxes.yml.erb'
  owner 'cyclescape'
  group 'cyclescape'
  mode '0400'
  variables(
    server: mb['server'],
    username: mb['username'],
    password: mb['password']
  )
end

api_keys = %w(rollbar akismet cyclestreets)
api_keys.each do |key|
  template deploy_dir + "/shared/config/#{key}" do
    source 'api-key.erb'
    owner 'cyclescape'
    group 'cyclescape'
    mode '0400'
    variables(api_key: data_bag_item('secrets', 'keys')[key])
  end
end

schedule_bag = data_bag_item('secrets', 'i18n')
template deploy_dir + "/shared/config/schedule.yml" do
  source "schedule.yml.erb"
  owner 'cyclescape'
  group 'cyclescape'
  mode '0400'
  variables(
    error_email: schedule_bag["error_email"],
    home: schedule_bag["home"],
    path: schedule_bag["path"]
  )
end

deploy_branch = (node['cyclescape']['environment'] == 'staging') ? 'staging' : 'master'

deploy_revision deploy_dir do
  bundler_depot = shared_path + '/bundle'
  repo 'https://github.com/cyclestreets/cyclescape.git'
  revision deploy_branch
  user 'cyclescape'
  group 'cyclescape'
  before_migrate do
    current_release_directory = release_path
    shared_directory = new_resource.shared_path
    running_deploy_user = new_resource.user
    shared_config = new_resource.shared_path + '/config'
    excluded_groups = %w(development test)

    # This must be called before any bundle execs
    script 'Bundling the gems' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      environment 'LC_ALL' => 'en_GB.UTF-8'
      code <<-EOS
        HOME=#{bundler_depot} BUNDLE_PATH=#{bundler_depot}\
        bundle install --deployment --path #{bundler_depot}\
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
    (api_keys + %w(database.yml mailboxes.yml)).each do |config|
      link File.join(current_release_directory, "config", config) do
        to File.join(shared_config, config)
      end
    end

    # Things for the dragonfly gem
    directory current_release_directory + '/tmp' do
      action :create
      owner 'cyclescape'
      group 'cyclescape'
    end

    directory File.join(shared_directory, "node_modules") do
      action :create
      owner 'cyclescape'
      group 'cyclescape'
    end

    ["node_modules", File.join(%w(tmp dragonfly))].each do |dir|
      link File.join(current_release_directory, dir) do
        to File.join(shared_directory, dir)
      end
    end

    %w(secret_token devise_secret_token secret_key_base).each do |secret|
      # We need to create a secret, and store it in the shared config
      # path for future use.
      script "create the #{secret}" do
        interpreter 'bash'
        cwd current_release_directory
        user running_deploy_user
        code "bundle exec rake secret > #{shared_config}/#{secret}"
        not_if "test -e #{shared_config}/#{secret}"
      end

      link current_release_directory + "/config/#{secret}" do
        to shared_config + "/#{secret}"
      end
    end

    script 'Create the database' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => node['cyclescape']['environment']
      code <<-EOH
        bundle exec rake db:create
      EOH
      not_if %q(test -n "`sudo -u postgres psql template1 -A -t -c '\l' | grep cyclescape_production`")
    end

    script 'Install npm modules' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      environment "NPM_CONFIG_CACHE" => "../../shared/npm/cache",
        "NPM_CONFIG_TMP" => "../../shared/npm/tmp"
      code "npm install"
      only_if do
        File.exists?(File.join(current_release_directory, 'package.json'))
      end
    end

    script 'Compile the assets' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => node['cyclescape']['environment']
      code <<-EOH
        bundle exec rake assets:precompile
      EOH
    end
  end

  before_restart do
    script 'Update seed data' do
      interpreter 'bash'
      cwd release_path
      user new_resource.user
      environment 'RAILS_ENV' => node['cyclescape']['environment']
      code "bundle exec rake db:seed"
    end

    # Create the server ENV
    script 'Update foreman configuration' do
      interpreter 'bash'
      cwd release_path
      code <<-EOH
        echo "RAILS_ENV=#{node['cyclescape']['environment']}" > .env
      EOH
    end

    # use foreman to create upstart files.
    script 'Update foreman configuration' do
      interpreter 'bash'
      cwd release_path
      code <<-EOH
        bundle exec foreman export upstart /etc/init -a cyclescape -u cyclescape -e .env
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
      only_if { node['cyclescape']['environment'] == 'production' }
    end
  end

  after_restart do
    script 'Reindex search' do
      interpreter 'bash'
      cwd release_path
      user new_resource.user
      environment 'RAILS_ENV' => node['cyclescape']['environment']

      code <<-EOH
        sleep 1m && bundle exec rake sunspot:reindex
      EOH
    end
  end

  migrate true
  migration_command 'bundle exec rake db:migrate'
  environment 'RAILS_ENV' => node['cyclescape']['environment']
  action :deploy
  restart_command 'touch tmp/restart.txt'
  # restart_command 'passenger-config restart-app /'
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
  variables environment: node['cyclescape']['environment']
  notifies :reload, 'service[apache2]'
end

link '/etc/apache2/sites-enabled/cyclescape.conf' do
  to '/etc/apache2/sites-available/cyclescape.conf'
  notifies :reload, 'service[apache2]'
end

# Enable ExtendedStatus in apache2
# This can be removed with later apache2 versions which have it included by default.
apache_conf 'status'
