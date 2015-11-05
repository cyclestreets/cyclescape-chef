default['firewall']['rules'] = [
  'http' => {
    'port' => '80'
  },
  'https' => {
    'port' => '443'
  }
]

default['cyclescape']['gem_folder'] = "#{default['brightbox-ruby']['version']}.0"
default['passenger']['ruby_bin'] = "/usr/bin/ruby#{default['brightbox-ruby']['version']}"
default['passenger']['version'] = '4.0.53'
