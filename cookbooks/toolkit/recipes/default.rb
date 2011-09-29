#
# Cookbook Name:: toolkit
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

include_recipe 'passenger'
include_recipe 'postgres'

directory "/var/www/toolkit/shared" do
  owner "www-data"
  group "www-data"
  recursive true
end

deploy "/var/www/toolkit" do
  repo "https://github.com/cyclestreets/toolkit.git"
  revision "master"
  user "www-data"
  migrate true
  migration_command "rake db:migrate"
  environment "RAILS_ENV" => "production"
  action :deploy
  restart_command "touch tmp/restart.txt"
end
