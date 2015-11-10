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
default['java']['jdk_version'] = 7
