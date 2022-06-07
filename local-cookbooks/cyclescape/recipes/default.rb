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

node.default['brightbox-ruby']['install_ruby_switch'] = system("update-alternatives --list ruby")

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

[
  deploy_dir, shared_dir,
  File.join(shared_dir, 'config'), File.join(shared_dir, 'log'),
  File.join(shared_dir, 'system'), File.join(shared_dir, 'tmp', 'dragonfly'),
  File.join(shared_dir, 'solr')
].each do |dir|
  directory dir do
    owner 'cyclescape'
    group 'cyclescape'
    recursive true
  end
end

include_recipe 'letsencrypt'

template deploy_dir + '/shared/config/database.yml' do
  source 'database.yml.erb'
  owner 'cyclescape'
  group 'cyclescape'
  mode '0644'
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

template '/etc/logrotate.d/rails-cyclescape' do
  source 'rails-cyclescape.erb'
  variables(shared_dir: shared_dir)
end

api_keys = %w(rollbar akismet cyclestreets facebook_app_id facebook_app_secret twitter_app_id twitter_app_secret)
api_keys.each do |key|
  template deploy_dir + "/shared/config/#{key}" do
    source 'api-key.erb'
    owner 'cyclescape'
    group 'cyclescape'
    mode '0400'
    variables(api_key: data_bag_item('secrets', 'keys').fetch(key))
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
    (api_keys + %w(database.yml mailboxes.yml schedule.yml)).each do |config|
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

    bash "Copy solr directory over" do
      cwd current_release_directory
      user running_deploy_user
      code "mv solr #{shared_dir}"
      not_if "test -d #{File.join(shared_dir, 'solr')}"
    end

    directory File.join(current_release_directory, "solr") do
      recursive true
      action :delete
    end

    ["node_modules", File.join(%w(tmp dragonfly)), "solr"].each do |dir|
      link File.join(current_release_directory, dir) do
        to File.join(shared_directory, dir)
      end
    end

    %w(secret_token devise_secret_token secret_key_base).each do |secret|
      # We need to create a secret, and store it in the shared config
      # path for future use.
      bash "create the #{secret}" do
        cwd current_release_directory
        user running_deploy_user
        environment 'RAILS_ENV' => node['cyclescape']['environment']
        code "bundle exec rake secret > #{shared_config}/#{secret}"
        not_if "test -e #{shared_config}/#{secret}"
      end

      link current_release_directory + "/config/#{secret}" do
        to shared_config + "/#{secret}"
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
        "FONTAWESOME_NPM_AUTH_TOKEN" => data_bag_item('secrets', 'keys').fetch('fontawsome_npm_auth')
      )
      code "npm install"
      only_if do
        File.exists?(File.join(current_release_directory, 'package.json'))
      end
    end

    # need to replace url with asset-url pointing to the node_modules path
    bash 'prepare fontawsome' do
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => node['cyclescape']['environment']
      code <<-EOH
        cp node_modules/@fortawesome/fontawesome-pro/css/all.css vendor/assets/stylesheets/_fontawesome.css
        sed -i 's:url("\.\.:asset-url("@fortawesome/fontawesome-pro:g' vendor/assets/stylesheets/_fontawesome.css
      EOH
      only_if do
        File.exists?("node_modules/@fortawesome/fontawesome-pro/css/all.css")
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

# Enable ExtendedStatus in apache2
# This can be removed with later apache2 versions which have it included by default.
apache_conf 'status'
