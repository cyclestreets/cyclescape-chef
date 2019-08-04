#
# Cookbook Name:: postgres
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

pg_version = '10'
postgis_pkg = 'postgresql-10-postgis-2.4'
if node['platform_version'] == '16.04'
  pg_version = '9.5'
  postgis_pkg = 'postgresql-9.5-postgis-2.2'
end

package "postgresql-#{pg_version}" do
  action :install
end

package "postgresql-contrib-#{pg_version}" do
  action :install
end

package "libpq-dev" do
  action :install
end

service 'postgresql' do
  supports reload: true, restart: true
  action :enable
end

package postgis_pkg do
  action :install
end
