default['firewall']['rules'] = [
  'http' => {
    'port' => '80'
  },
  'https' => {
    'port' => '443'
  },
  'munin' => {
    'port' => '4949'
  },
]

default['apache']['listen_ports'] = %w(80 443)
default["brightbox-ruby"]["version"] = "3.0"
default['brightbox-ruby']['default_action'] = :install
default['ruby_build']['upgrade'] = true
default['java']['jdk_version'] = 8

default['apache']['prefork']['startservers'] = 4
default['cyclescape']['ruby_dir'] = "/usr/local/sbin/"
default['passenger']['ruby_bin'] = "#{default['cyclescape']['ruby_dir']}ruby"
default['passenger']['version'] = '6.0.23'

default['apt']['unattended_upgrades']['enable'] = true
default['apt']['unattended_upgrades']['auto_fix_interrupted_dpkg'] = true

node.default['nodejs']['install_method'] = 'binary'
node.default['nodejs']['version'] = '14.21.1'
node.default['nodejs']['binary']['checksum'] = ''
default['cyclescape']['basic_auth']['username'] = 'staginguser'
default['cyclescape']['basic_auth']['password'] = 'staging'
default['cyclescape']['ruby_version'] = '3.3.6'

default['exim4']['configtype'] = 'satellite'
default['exim4']['hide_mailname'] = 'true'
default['exim4']['localdelivery'] = 'mail_spool'
