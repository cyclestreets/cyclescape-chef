#
# Cookbook Name:: cyclescape-user
# Recipe:: default
#
# Copyright 2012, Cyclestreets Ltd

user 'cyclescape' do
  action :create
  shell '/bin/bash'
  home '/home/cyclescape'
  manage_home true
end
