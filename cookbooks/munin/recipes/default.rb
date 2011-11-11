#
# Cookbook Name:: munin
# Recipe:: default
#
# Copyright 2011, Cyclestreets

include_recipe 'apache2'

%w{munin munin-node}.each do |p|
  package p
end

template "/etc/munin/munin.conf" do
  source "munin.conf"
  mode "0644"
end

template "/etc/apache2/sites-available/munin" do
  source "munin.vhost.conf"
  notifies :reload, "service[apache2]"
end

apache_site "munin"
