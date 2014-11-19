#
# Cookbook Name:: cyclescape
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

# This recipe sets up some dummy SSL certificates,
# so that apache will load without complaining.

# Install the actual startcom certificates used for
# the live operations

cert_dir = '/etc/apache2/ssl/'

directory cert_dir do
  owner 'www-data'
  action :create
  recursive true
end

certs = {
  # Files obtained from http://www.startssl.com/certs/
  :startcom_ca => 'startcom.ca.cer',
  :startcom_server => 'startcom.sub.class2.server.ca.cer',

  # These are dummy, self-signed certificates that need to
  # be replaced on the live server
  :cyclescape_cert => 'cyclescape-org.ssl.crt',
  :cyclescape_key => 'cyclescape-org.ssl.nopassword.key'
}

certs.each_value do |cert|
  cookbook_file File.join(cert_dir, cert) do
    source cert
    owner 'root'
    mode '0600'
    action :create_if_missing
  end
end
