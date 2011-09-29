#
# Cookbook Name:: passenger
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

apt_repository "brightbox" do
  uri "http://apt.brightbox.net"
  distribution "lucid" # these guys need some updated distributions!
  components ["main"]
  action :add
end

package "libapache2-mod-passenger" do
  action :install
end