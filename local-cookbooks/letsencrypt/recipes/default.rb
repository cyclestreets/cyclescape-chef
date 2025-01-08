#
# Cookbook Name:: letsencrypt
# Recipe:: default
#
# Copyright 2018, Cyclestreets Ltd

package 'dehydrated'

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
  content node["letsencrypt"]["domain_names"].map { |domain| "*.#{domain} > #{domain}" }.join("\n")
end

file '/etc/dehydrated/dnsapi.config.txt' do
  owner 'root'
  group 'root'
  mode '0400'
  content(
    node["letsencrypt"]["domain_names_and_passwords"].map { |hsh| hsh.to_a.join(" ") }.join("\n") + "\n"
  )
end

file "/etc/dehydrated/conf.d/hook.sh" do
  owner 'root'
  group 'root'
  content <<-BASH
HOOK=/etc/dehydrated/dehydrated-mythic-dns01/dehydrated-mythic-dns01.sh
CHALLENGETYPE=dns-01
HOOK_CHAIN=yes
AUTO_CLEANUP=yes
  BASH
end

file "/etc/dehydrated/conf.d/mail.sh" do
  owner 'root'
  group 'root'
  content <<-BASH
CONTACT_EMAIL=#{node["letsencrypt"]["error_email"]}
  BASH
end

script 'Accept TOS' do
  interpreter 'bash'
  code <<-EOS
    dehydrated --register --accept-terms
  EOS
end

dehydrated_cert = "/var/lib/dehydrated/certs"
dehydrated_log = "/var/log/dehydrated-cron.log"

file "/etc/cron.daily/dehydrated" do
  owner 'root'
  group 'root'
  content <<-BASH
#!/bin/sh
LOGFILE=#{dehydrated_log}
APACHE_SSL=/etc/apache2/ssl/
echo "Cron Job running at `date`" >> ${LOGFILE}
/usr/bin/dehydrated -c >> ${LOGFILE} 2>&1

# Find any pem files changed in the last 30 mins
CHANGED=`/usr/bin/find #{File.join(dehydrated_cert, node["letsencrypt"]["domain_names"][0])} -mmin -30 -name "*.pem" -ls`
echo "CHANGED=${CHANGED}" >> ${LOGFILE}

# If changed files is not empty then symlink over and update apache
if [[ ! -z $CHANGED ]]; then
  echo "The certificates have changed, relinking and reloading apache" >> ${LOGFILE}
  /bin/ln -sf #{File.join(dehydrated_cert, node["letsencrypt"]["domain_names"][0], "*")} "${APACHE_SSL}"
  /etc/init.d/apache2 reload >> ${LOGFILE}
  find "${APACHE_SSL}" -xtype l -delete
fi
  BASH
  mode '0755'
end

file "/etc/logrotate.d/dehydrated" do
  owner 'root'
  group 'root'
  content <<-BASH
#{dehydrated_log}
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
