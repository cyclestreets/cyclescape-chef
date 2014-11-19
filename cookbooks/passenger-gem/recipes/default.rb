#
# Cookbook Name:: passenger-gem
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

include_recipe 'apache2'

%w(
  build-essential
  libcurl4-openssl-dev
  libssl-dev
  zlib1g-dev
  apache2-prefork-dev
  libapr1-dev
  libaprutil1-dev
).each do |p|
  package p
end

gem_package 'passenger' do
  gem_binary '/usr/bin/gem1.9.1'
  action :install
  version node['passenger-gem']['version']
end

script 'install the passenger module' do
  interpreter 'bash'
  cwd '/tmp'
  code <<-EOH
    /usr/local/bin/passenger-install-apache2-module --auto
  EOH
  not_if "test -f /var/lib/gems/1.9.1/gems/passenger-#{node['passenger-gem']['version']}/ext/apache2/mod_passenger.so"
end

template '/etc/apache2/mods-available/passenger.load' do
  source 'passenger.module.conf'
  mode '0644'
  notifies :restart, 'service[apache2]'
  variables(passenger_version: node['passenger-gem']['version'])
end

link '/etc/apache2/mods-enabled/passenger.load' do
  to '/etc/apache2/mods-available/passenger.load'
  notifies :restart, 'service[apache2]'
end
