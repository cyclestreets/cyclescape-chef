default['firewall']['rules'] = [
  'http' => {
    'port' => '80'
  },
  'https' => {
    'port' => '443'
  },
  'munin' => {
    'port' => '4949'
  }
]

default['apache']['listen_ports'] = %w(80 443)
default['passenger']['ruby_bin'] = "/usr/bin/ruby#{default['brightbox-ruby']['version']}"
default['passenger']['version'] = '5.0.20'
default['brightbox-ruby']['install_ruby_switch'] = true
default['brightbox-ruby']['rubygems_version'] = '2.5.1'
default['java']['jdk_version'] = 7

default['apache']['prefork']['startservers'] = 5
default['apache']['prefork']['minspareservers'] = 5
default['apache']['prefork']['maxspareservers'] = 8
