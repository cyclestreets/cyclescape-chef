#
# Cookbook Name:: ruby-brightbox
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

# I hate having multiple rubies, but I hate having rvm even more

# Due to the joys of debian package names, these are actually 1.9.2

apt_repository "ruby-ng" do
  uri "https://launchpad.net/~brightbox/+archive/ubuntu/ruby-ng"
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6"
  action :add
end

package 'ruby2.1'
