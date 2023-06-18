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

pg_config_file = `sudo -u postgres psql -t -P format=unaligned -c 'SHOW config_file'`
bash "Add pg_stat_statements to pg_config_file" do
  code <<-EOL
    echo "shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all" >> #{pg_config_file}
  EOL
  only_if do
    !::File.foreach(pg_config_file.strip).grep(/pg_stat_statements\.track = all/).any?
  end
end
