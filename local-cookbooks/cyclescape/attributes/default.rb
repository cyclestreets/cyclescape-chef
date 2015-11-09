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

default['cyclescape']['gem_folder'] = "#{default['brightbox-ruby']['version']}.0"
default['passenger']['ruby_bin'] = "/usr/bin/ruby#{default['brightbox-ruby']['version']}"
default['passenger']['version'] = '4.0.53'
default['brightbox-ruby']['install_ruby_switch'] = true
default['java']['jdk_version'] = 7
