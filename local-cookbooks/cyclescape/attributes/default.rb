default['cyclescape']['firewall']['rules'] = [
  'http' => {
    'port' => '80'
  },
  'https' => {
    'port' => '443'
  }
]

default['cyclescape']['gem_folder'] = "#{default['brightbox-ruby']['version']}.0"
