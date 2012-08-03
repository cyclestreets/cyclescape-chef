#
# Cookbook Name:: cyclekit-user
# Recipe:: default
#
# Copyright 2012, Cyclestreets Ltd

user "cyclekit" do
  action :create
  shell "/bin/bash"
end
