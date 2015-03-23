#
# Cookbook Name:: cyclescape-user
# Recipe:: default
#
# Copyright 2012, Cyclestreets Ltd

user node['user'] do
  action :create
  shell '/bin/bash'
end
