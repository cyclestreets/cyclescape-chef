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
default["brightbox-ruby"]["version"] = "2.7"
default['brightbox-ruby']['default_action'] = :install
default['java']['jdk_version'] = 8

default['apache']['prefork']['startservers'] = 4
default['passenger']['ruby_bin'] = "/usr/bin/ruby#{default['brightbox-ruby']['version']}"
default['passenger']['version'] = '6.0.12' # 6.0.13 drops ruby 2.5
default['passenger']['root_path'] = "#{languages['ruby']['gems_dir']}/gems/passenger-#{default['passenger']['version']}"
node.default['nodejs']['install_method'] = 'binary'
node.default['nodejs']['version'] = '12.22.1'
node.default['nodejs']['binary']['checksum'] = ''
default['cyclescape']['basic_auth']['username'] = 'staginguser'
default['cyclescape']['basic_auth']['password'] = 'staging'
