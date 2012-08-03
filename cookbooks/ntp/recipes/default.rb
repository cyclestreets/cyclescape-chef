#
# Cookbook Name:: ntp
# Recipe:: default
#
# Copyright 2012, Cyclestreets Ltd.

package "ntp"

service "ntp" do
  supports :restart => true
end

template "/etc/ntp.conf" do
  source "ntp.conf"
  notifies :restart, "service[ntp]"
end

directory "/etc/ntp"

template "/etc/ntp/step-tickers" do
  source "step-tickers"
  notifies :restart, "service[ntp]"
end
