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
  'npt' => {
    'port' => '123',
    'protocol' => 'udp'
  }
]

default['apache']['listen_ports'] = %w(80 443)
default["brightbox-ruby"]["version"] = "3.0"
default['brightbox-ruby']['default_action'] = :install
default['java']['jdk_version'] = 8

default['apache']['prefork']['startservers'] = 4
default['passenger']['ruby_bin'] = "/usr/bin/ruby#{default['brightbox-ruby']['version']}"
default['passenger']['version'] = '6.0.23'
default['passenger']['bin_dir'] = '/usr/bin/'

# no idea why these are needed
default['passenger']['root_path'] = "#{languages['ruby']['gems_dir']}/gems/passenger-#{default['passenger']['version']}"
default['passenger']['module_path'] = "#{node['passenger']['root_path']}/#{Chef::Recipe::PassengerConfig.build_directory_for_version(node['passenger']['version'])}/apache2/mod_passenger.so"

node.default['nodejs']['install_method'] = 'binary'
node.default['nodejs']['version'] = '14.21.1'
node.default['nodejs']['binary']['checksum'] = ''
default['cyclescape']['basic_auth']['username'] = 'staginguser'
default['cyclescape']['basic_auth']['password'] = 'staging'

default['exim4']['configtype'] = 'satellite'
default['exim4']['hide_mailname'] = 'true'
default['exim4']['localdelivery'] = 'mail_spool'
