#
# Cookbook Name:: postgres
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

if node['platform'] == 'ubuntu' && node['platform_version'] == '14.04'
  pg_version = '9.3'
  postgis_pkg = 'postgresql-9.3-postgis-2.1'
else
  pg_version = '9.1'
  postgis_pkg = 'postgresql-9.1-postgis'
end

package "postgresql-#{pg_version}" do
  action :install
end

package "postgresql-contrib-#{pg_version}" do
  action :install
end

service 'postgresql' do
  supports reload: true, restart: true
  action :enable
end

package postgis_pkg do
  action :install
end
