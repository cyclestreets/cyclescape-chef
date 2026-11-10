#
# Cookbook Name:: postgres
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

package "postgresql" do
  action :install
end

package "postgresql-contrib" do
  action :install
end

package "libpq-dev" do
  action :install
end

service 'postgresql' do
  supports reload: true, restart: true
  action :enable
end

package "postgis" do
  action :install
end

file 'pg_stat_statements.conf' do
  path lazy {
    config_file = shell_out!('psql -tAc "SHOW config_file"', user: 'postgres').stdout.strip
    ::File.join(::File.dirname(config_file), 'conf.d', 'pg_stat_statements.conf')
  }
  content "shared_preload_libraries = 'pg_stat_statements'\npg_stat_statements.track = all\n"
  notifies :restart, 'service[postgresql]'
end
