#
# Cookbook Name:: postgres
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

pg_version = '12'
postgis_pkg = "postgresql-#{pg_version}-postgis-3"
if node['platform_version'] == '18.04'
  pg_version = '10'
  postgis_pkg = "postgresql-#{pg_version}-postgis-2.4"
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

pg_config_file = "/etc/postgresql/#{pg_version}/main/postgresql.conf"
bash "Add pg_stat_statements to pg_config_file" do
  code <<-EOL
    echo "shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all" >> #{pg_config_file}
  EOL
  only_if do
    ::File.exists?(pg_config_file) && !File.foreach(pg_config_file).grep(/pg_stat_statements\.track = all/).any?
  end
end
