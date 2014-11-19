#
# Cookbook Name:: munin-plugins-rails
# Recipe:: default
#
# Copyright 2013, Cyclestreets Ltd

include_recipe 'munin'

gem_package 'munin-plugins-rails' do
  gem_binary '/usr/bin/gem1.9.1'
  action :install
end

script 'install passenger munin plugins' do
  interpreter 'bash'
  code <<-EOH
    request-log-analyzer-munin install
  EOH
  not_if 'test -e /etc/munin/plugin-conf.d/munin_passenger_memory_stats'
  notifies :restart, 'service[munin-node]'
end

# override all the config files, to fix the ruby path

%w{munin_passenger_memory_stats  munin_passenger_queue  munin_passenger_status}.each do |f|
  template File.join('/etc/munin/plugin-conf.d/', f) do
    source f
    notifies :restart, 'service[munin-node]'
  end
end

script 'install rails munin plugins' do
  interpreter 'bash'
  code <<-EOH
    request-log-analyzer-munin add cyclescape /var/www/cyclescape/shared/log/production.log
  EOH
  notifies :restart, 'service[munin-node]'
  not_if 'test -e /etc/munin/plugin-conf.d/cyclescape_munin_rails_requests'
end

# again, override the config files, to fix the ruby path

%w{cyclescape_munin_rails_database_time
   cyclescape_munin_rails_request_error
   cyclescape_munin_rails_view_render_time
   cyclescape_munin_rails_request_duration
   cyclescape_munin_rails_requests
}.each do |f|
  template File.join('/etc/munin/plugin-conf.d/', f) do
    source f
    notifies :restart, 'service[munin-node]'
  end
end
