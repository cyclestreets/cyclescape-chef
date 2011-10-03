#
# Cookbook Name:: toolkit
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

include_recipe 'passenger'
include_recipe 'postgres'
include_recipe 'ruby19'

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
