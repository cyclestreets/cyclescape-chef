#
# Cookbook Name:: postfix
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

package "postfix"

service "postfix"

# Inspired by http://pauldowman.com/2008/02/17/smtp-mail-from-ec2-web-server-setup
template "/etc/postfix/main.cf" do
  source "main.cf"
  mode "0644"
  notifies :restart, "service[postfix]"
end
