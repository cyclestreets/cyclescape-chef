#
# Cookbook Name:: munin
# Recipe:: default
#
# Copyright 2011, Cyclestreets

include_recipe 'apache2'

%w{munin munin-node libdbd-pg-perl}.each do |p|
  package p
end

template '/etc/munin/munin.conf' do
  source 'munin.conf'
  mode '0644'
end

template '/etc/munin/munin-node.conf' do
  source 'munin-node.conf'
  mode '0644'
  notifies :restart, 'service[munin-node]'
end

service 'munin-node'

# Normal postgres plugins
%w{ postgres_bgwriter
    postgres_checkpoints
    postgres_users
    postgres_xlog
}.each do |p|
  link File.join('/etc/munin/plugins', p) do
    to File.join('/usr/share/munin/plugins', p)
    notifies :restart, 'service[munin-node]'
  end
end

# Clever little postgres scripts that monitor specific
# databases, or ALL of them
%w{ postgres_size_
    postgres_connections_
    postgres_locks_
    postgres_transactions_
    postgres_cache_
    postgres_querylength_
    postgres_scans_
    postgres_tuples_
}.each do |p|
  link File.join('/etc/munin/plugins', p + 'ALL') do
    to File.join('/usr/share/munin/plugins', p)
    notifies :restart, 'service[munin-node]'
  end
end

%w{ apache_accesses
    apache_processes
    apache_volume
}.each do |p|
  link File.join('/etc/munin/plugins', p) do
    to File.join('/usr/share/munin/plugins', p)
    notifies :restart, 'service[munin-node]'
  end
end

template '/etc/apache2/sites-available/munin' do
  source 'munin.vhost.conf'
  notifies :reload, 'service[apache2]'
end

apache_site 'munin'
