#
# Cookbook Name:: postgres
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

apt_repository "pitti" do
  uri "http://ppa.launchpad.net/pitti/postgresql/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "8683D8A2"
  action :add
end

package "postgresql-9.0" do
  action :install
end

package "postgresql-contrib-9.0" do
  action :install
end

service "postgresql" do
  supports :reload => true, :restart => true
  action :enable
end

# https://launchpad.net/~ubuntugis/+archive/ubuntugis-unstable
# purely for libgeos-c1 needed for postgis
apt_repository "ubuntugis-stable" do
  uri "http://ppa.launchpad.net/ubuntugis/ppa/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "314DF160"
  action :add
end

# https://launchpad.net/~pi-deb/+archive/gis
apt_repository "pi-deb" do
  uri "http://ppa.launchpad.net/pi-deb/gis/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "226213AA"
  action :add
end

package "postgresql-9.0-postgis" do
  action :install
end

