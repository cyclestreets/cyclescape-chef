#
# Cookbook Name:: ruby-brightbox
# Recipe:: default
#
# Copyright 2015, Cyclestreets Ltd

apt_repository "ruby-ng" do
  uri "http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu"
  components ["main"]
  distribution 'trusty'
  keyserver "keyserver.ubuntu.com"
  key "C3173AA6"
  action :add
end

package 'ruby2.1'
package 'ruby2.1-dev'

