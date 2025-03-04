#
# Cookbook Name:: cyclescape
# Recipe:: default
#
# Copyright 2015, Cyclestreets Ltd

ENV["PATH"] = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
include_recipe 'apt'
include_recipe 'apt::unattended-upgrades'
include_recipe 'ssl'
include_recipe 'apache2'
include_recipe 'postgres'

include_recipe 'java'

# https://github.com/phusion/passenger/issues/2397
cookbook_file "/usr/lib/tmpfiles.d/passenger.conf" do
  source "name_too_long_passenger.conf"
end
directory "/var/run/passenger-instreg"

cookbook_file "/etc/gemrc" do
  action :create_if_missing
  source "gemrc"
  mode   "0644"
end

include_recipe 'ruby_build'

ruby_build_ruby node["cyclescape"]["ruby_version"]

Dir["/usr/local/ruby/#{node['cyclescape']['ruby_version']}/bin/*"].each do |ruby_file|
  link "#{node['cyclescape']['ruby_dir']}#{File.basename(ruby_file)}" do
    to ruby_file
  end
end

gem_package 'rack' do # needed old rake gems have rackup but passenger_apache2 installs rackup as a spearate gem
  action :install
  version "3.1.7"
end

gem_dir = `#{node['passenger']['ruby_bin']} -e "puts ::Gem.dir"`
# no idea why these are needed
node.default['passenger']['root_path'] = "#{gem_dir.strip}/gems/passenger-#{node['passenger']['version']}"
node.default['passenger']['module_path'] = "#{node['passenger']['root_path']}/#{Chef::Recipe::PassengerConfig.build_directory_for_version(node['passenger']['version'])}/apache2/mod_passenger.so"

include_recipe 'passenger_apache2'

node.default['exim4']['smarthost_server'] = data_bag_item("secrets", "mailbox")["relayhost"]
node.default['exim4']['mailname'] = 'cyclescape.org'
node.default['exim4']['readhost'] = 'cyclescape.org'

include_recipe 'exim4-light'
file '/etc/exim4/exim4.conf.localmacros' do
  content 'MAIN_TLS_ENABLE = no'
  mode '0644'
  owner 'root'
  group 'root'
end

include_recipe 'cyclescape-user'
include_recipe 'cyclescape-backups'
include_recipe 'ufw'
include_recipe 'munin-plugins-rails'
include_recipe 'nodejs'

deploy_dir = '/var/www/cyclescape'
shared_dir = File.join(deploy_dir, 'shared')
node.default['letsencrypt']['error_email'] = data_bag_item("secrets", "i18n")["error_email"]
node.default['letsencrypt']['domain_names'] = [node['cyclescape']['server_name']]
node.default['letsencrypt']['domain_names_and_passwords'] = [data_bag_item('secrets', 'dns')["domain_name"] => data_bag_item('secrets', 'dns')["dns_api_password"]]
node.default['letsencrypt']['working_dir'] = shared_dir

# Geos dev package for RGeo gem
package 'libgeos-dev'
package 'apache2-utils'

# Redis server for queueing and caching
package 'redis-server'

# Imagemagick, for dragonfly to do image processing with convert
package 'imagemagick'

# not actually for the app, just for some other scripts we have
package 's-nail'

# git - useful when running testing the scripts with Vagrant. Normally
# installed manually in order to acquire the cookbooks, as per README
package 'git'

apache_module 'rewrite'
apache_module 'socache_shmcb'
apache_module 'ssl'
apache_module 'expires'
apache_module 'headers'

# Create the database user. For now, it's a superuser.
bash 'create cyclescape db user' do
  user 'postgres'
  group 'postgres'
  cwd '/var/lib/postgresql'
  code <<-EOH
    createuser cyclescape -s
  EOH
  not_if %q(test -n "`sudo -u postgres psql template1 -A -t -c '\du cyclescape'`") # Mmm, hacky
end

shared_dirs_to_copy = [ File.join('tmp', 'dragonfly'), File.join('solr', 'default', 'data'), File.join('solr', 'pid') ]

[
  deploy_dir,
  File.join(shared_dir, 'config', 'credentials'), File.join(shared_dir, 'log'), File.join(shared_dir, 'system'),
  *shared_dirs_to_copy.map { |sd| File.join(shared_dir, sd) }
].each do |dir|
  directory dir do
    owner 'cyclescape'
    group 'cyclescape'
    recursive true
  end
end

include_recipe 'letsencrypt'

template '/etc/logrotate.d/rails-cyclescape' do
  source 'rails-cyclescape.erb'
  variables(shared_dir: shared_dir)
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
  symlink_before_migrate.clear
  user 'cyclescape'
  group 'cyclescape'
  before_migrate do
    current_release_directory = release_path
    shared_directory = new_resource.shared_path
    running_deploy_user = new_resource.user
    shared_config = new_resource.shared_path + '/config'
    excluded_groups = %w(development test staging) - [node['cyclescape']['environment']]
    gem_lock = File.join(release_path, "Gemfile.lock")

    # Install the bundler version used in the Gemfile.lock
    gem_package 'bundler' do
      action :install
      version "#{ File.file?(gem_lock) ? File.open(gem_lock).to_a.last.strip : '1.17.1' }"
    end

    # This must be called before any bundle execs
    bash 'Bundling the gems' do
      cwd current_release_directory
      user running_deploy_user
      environment 'LC_ALL' => 'en_GB.UTF-8'
      code <<-EOS
        HOME=#{bundler_depot} BUNDLE_PATH=#{bundler_depot}\
        bundle install --deployment --path #{bundler_depot} --quiet\
        --without #{excluded_groups.join(' ')}
      EOS
    end

    # Stop any cron jobs from running during migration
    bash 'Clear crontab' do
      cwd current_release_directory
      user running_deploy_user
      code <<-EOH
        bundle exec whenever --clear-crontab cyclescape_app
      EOH
    end

    # The symlink_before_default does this, but annoyingly comes after before_migrate is called
    # That way, db:create fails. So do it manually instead...
    %w(schedule.yml).each do |config|
      link File.join(current_release_directory, "config", config) do
        to File.join(shared_config, config)
      end
    end

    template current_release_directory + "/config/credentials/#{node["cyclescape"]["environment"]}.key" do
      source 'api-key.erb'
      owner 'cyclescape'
      group 'cyclescape'
      mode '0400'
      variables(api_key: data_bag_item('secrets', "keys").fetch("credentials"))
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

    ["node_modules", *shared_dirs_to_copy].each do |dir|
      link File.join(current_release_directory, dir) do
        to File.join(shared_directory, dir)
      end
    end

    bash 'Create the database' do
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => node['cyclescape']['environment']
      code <<-EOH
        bundle exec rake db:create
      EOH
      not_if %q(test -n "`sudo -u postgres psql template1 -A -t -c '\l' | grep cyclescape_production`")
    end

    bash 'Install npm version' do # No idea why the nodejs cookbook doesn't do this...
      code "npm install -g npm@8.2.0"
      not_if %q{test -n "`npm -v | grep 8.2.0`"}
    end

    bash 'Install npm modules' do
      cwd current_release_directory
      user running_deploy_user
      environment(
        "NPM_CONFIG_CACHE" => "../../shared/npm/cache",
        "NPM_CONFIG_TMP" => "../../shared/npm/tmp",
        "NODE_ENV" => "production",
      )
      code "npm install"
      only_if do
        File.exists?(File.join(current_release_directory, 'package.json'))
      end
    end

    bash 'Compile the assets' do
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => node['cyclescape']['environment']
      code <<-EOH
        bundle exec rake assets:precompile
      EOH
    end
  end

  before_restart do
    bash 'Update seed data' do
      cwd release_path
      user new_resource.user
      environment 'RAILS_ENV' => node['cyclescape']['environment']
      code "bundle exec rake db:seed"
    end

    # Create the server ENV
    bash 'Update env configuration' do
      cwd release_path
      code <<-EOH
        echo "RAILS_ENV=#{node['cyclescape']['environment']}" > .env
      EOH
    end

    bash 'Update foreman configuration' do
      cwd release_path
      code <<-EOH
        bundle exec foreman export systemd /etc/systemd/system -a cyclescape -u cyclescape -e .env
        for service_filename in /etc/systemd/system/cyclescape-*/*.service; do
          echo "TasksMax=infinity" >> "$service_filename"
        done
        systemctl daemon-reload
      EOH
    end

    service "cyclescape.target" do
      provider Chef::Provider::Service::Systemd
      supports restart: true
      action [:restart, :enable]
    end

    bash 'Set crontab' do
      cwd release_path
      user new_resource.user
      code <<-EOH
        bundle exec whenever -i cyclescape_app --update-crontab
      EOH
      only_if { node['cyclescape']['environment'] == 'production' }
    end

    bash 'reload cron' do # old cron seemed to persist
      code "/etc/init.d/cron reload"
    end
  end

  migrate true
  migration_command <<~EOH
    echo #{node['cyclescape']['environment']};
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin RAILS_ENV=#{node['cyclescape']['environment']} bundle exec rake db:migrate
  EOH
  environment 'RAILS_ENV' => node['cyclescape']['environment']
  action :deploy
  restart_command 'touch tmp/restart.txt'
  # restart_command 'passenger-config restart-app /'
end

bash 'create htpasswd file' do
  only_if { node["cyclescape"]["environment"] == "staging" }
  code <<-EOH
    htpasswd -bc /etc/apache2/passwords #{node["cyclescape"]["basic_auth"]["username"]} #{node["cyclescape"]["basic_auth"]["password"]}
  EOH
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
  variables(
    environment: node['cyclescape']['environment'],
    server_name: node['cyclescape']['server_name'],
    basic_auth_username: node['cyclescape']['basic_auth']['username'],
    basic_auth_password: node['cyclescape']['basic_auth']['password']
  )
  notifies :reload, 'service[apache2]'
end

link '/etc/apache2/sites-enabled/cyclescape.conf' do
  to '/etc/apache2/sites-available/cyclescape.conf'
  notifies :reload, 'service[apache2]'
end

service 'systemd-timesyncd' do
  action [:enable, :start]
end
