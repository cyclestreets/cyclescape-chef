#
# Cookbook Name:: letsencrypt
# Recipe:: default
#
# Copyright 2018, Cyclestreets Ltd

include_recipe 'apt'

remote_file File.join(node['letsencrypt']['working_dir'], 'dehydrated.deb') do
  source 'http://archive.ubuntu.com/ubuntu/pool/universe/d/dehydrated/dehydrated_0.4.0-2_all.deb'
  action :create_if_missing
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

# Find any pem files changed in the last 30 mins
CHANGED=`find /etc/letsencrypt/live/cyclescape.org -mmin -30 -name "*.pem" -ls`

# If changed files is not empty then symlink over and update apache
if [[ ! -z $CHANGED ]]; then
ln -sf /etc/letsencrypt/live/cyclescape.org/* /etc/apache2/ssl/
/etc/init.d/apache2 reload
fi
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
