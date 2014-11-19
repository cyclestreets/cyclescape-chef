#
# Cookbook Name:: postgres
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

package 'postgresql-9.1' do
  action :install
end

package 'postgresql-contrib-9.1' do
  action :install
end

service 'postgresql' do
  supports :reload => true, :restart => true
  action :enable
end

package 'postgresql-9.1-postgis' do
  action :install
end
