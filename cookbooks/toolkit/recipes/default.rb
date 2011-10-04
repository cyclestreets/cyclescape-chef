#
# Cookbook Name:: toolkit
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

include_recipe 'apache2'
include_recipe 'postgres'
include_recipe 'ruby19'
include_recipe 'passenger-gem'

# We can install bundler with the ubuntu version of gem ...
gem_package "bundler" do
  gem_binary "/usr/bin/gem1.9.1"
  action :install
end

# ... but it installs binaries into a non-PATH directory
# See http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=448639
link "/usr/bin/bundle" do
  to "/var/lib/gems/1.9.1/bin/bundle"
end

# Install a very old version of nodejs
package "nodejs"

user "cyclekit" do
  action :create
end

# Create the database user. For now, it's a superuser.
script "create cyclekit db user" do
  interpreter "bash"
  user "postgres"
  group "postgres"
  cwd "/var/lib/postgresql"
  code <<-EOH
    createuser cyclekit -s
  EOH
  not_if %q{test -n "`sudo -u postgres psql template1 -A -t -c '\du cyclekit'`"} # Mmm, hacky
end

deploy_dir = "/var/www/toolkit"
shared_dir = File.join(deploy_dir, "shared")

[deploy_dir, File.join(shared_dir, "config"), File.join(shared_dir, "log"), File.join(shared_dir, "system")].each do |dir|
  directory dir do
    owner "cyclekit"
    group "cyclekit"
    recursive true
  end
end

template deploy_dir + "/shared/config/database.yml" do
  source "database.example.yml"
  owner "cyclekit"
  group "cyclekit"
  mode "0644"
end

deploy_revision deploy_dir do
  repo "https://github.com/cyclestreets/toolkit.git"
  revision "master"
  user "cyclekit"
  group "cyclekit"
  before_migrate do
    current_release_directory = release_path
    running_deploy_user = new_resource.user
    bundler_depot = new_resource.shared_path + '/bundle'
    shared_config = new_resource.shared_path + '/config'
    excluded_groups = %w(development test)

    script 'Bundling the gems' do
      interpreter 'bash'
      cwd current_release_directory
      user running_deploy_user
      code <<-EOS
        bundle install --quiet --deployment --path #{bundler_depot} \
        --without #{excluded_groups.join(' ')}
      EOS
    end

    # The symlink_before_default does this, but annoyingly comes after before_migrate is called
    # That way, db:create fails. So do it manually instead...
    link current_release_directory + '/config/database.yml' do
      to shared_config + '/database.yml'
    end

    script 'Create the database' do
      interpreter "bash"
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => 'production'
      code <<-EOH
        bundle exec rake db:create
      EOH
      not_if %q{test -n "`sudo -u postgres psql template1 -A -t -c '\l' | grep cyclekit_production`"}
    end

    script 'Compile the assets' do
      interpreter "bash"
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => 'production'
      code <<-EOH
        bundle exec rake assets:precompile
      EOH
    end
  end
  migrate true
  migration_command "bundle exec rake db:migrate"
  environment "RAILS_ENV" => "production"
  action :deploy
  restart_command "touch tmp/restart.txt"
end

# sort out the virtual hosts, with delayed reloading of apache2
link "/etc/apache2/sites-enabled/000-default" do
  action :delete
  only_if "test -L /etc/apache2/sites-enabled/000-default"
  notifies :reload, "service[apache2]"
end

template "/etc/apache2/sites-available/toolkit" do
  source "passenger.vhost.conf"
  owner "www-data"
  group "www-data"
  mode "0644"
  notifies :reload, "service[apache2]"
end

link "/etc/apache2/sites-enabled/toolkit" do
  to "/etc/apache2/sites-available/toolkit"
  notifies :reload, "service[apache2]"
end
