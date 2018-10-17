#
# Cookbook Name:: letsencrypt
# Recipe:: default
#
# Copyright 2018, Cyclestreets Ltd

include_recipe 'apt'

remote_file 'dehydrated.deb' do
  source 'http://archive.ubuntu.com/ubuntu/pool/universe/d/dehydrated/dehydrated_0.4.0-2_all.deb'
  action :create
end

dpkg_package 'dehydrated' do
  source 'dehydrated.deb'
  action :install
end

package 'dnsutils'

git "/etc/dehydrated" do
  repository "https://github.com/mythic-beasts/dehydrated-mythic-dns01.git"
  destination "/etc/dehydrated/dehydrated-mythic-dns01"
  reference "master"
  action :sync
end

file '/etc/dehydrated/domains.txt' do
  owner 'root'
  group 'root'
  content node["letsencrypt"]["domain_names"].join(" ")
end

file '/etc/dehydrated/dnsapi.config.txt' do
  owner 'root'
  group 'root'
  mode '0400'
  content(
    node["letsencrypt"]["domain_names_and_passwords"].map { |hsh| hsh.to_a.join(" ") }.join("\n")
  )
end

file "/etc/dehydrated/conf.d/hook.sh" do
  owner 'root'
  group 'root'
  content <<-BASH
HOOK=/etc/dehydrated/dehydrated-mythic-dns01/dehydrated-mythic-dns01.sh
CHALLENGETYPE=dns-01
HOOK_CHAIN=yes
  BASH
end

file "/etc/dehydrated/conf.d/mail.sh" do
  owner 'root'
  group 'root'
  content <<-BASH
CONTACT_EMAIL=#{node["letsencrypt"]["error_email"]}
  BASH
end

file "/etc/cron.daily/dehydrated" do
  owner 'root'
  group 'root'
  content <<-BASH
#!/bin/sh
exec /usr/bin/dehydrated -c >>/var/log/dehydrated-cron.log 2>&1
  BASH
  mode '0755'
end

file "/etc/logrotate.d/dehydrated" do
  owner 'root'
  group 'root'
  content <<-BASH
/var/log/dehydrated-cron.log
{
        rotate 12
        monthly
        missingok
        notifempty
        delaycompress
        compress
}
  BASH
end
