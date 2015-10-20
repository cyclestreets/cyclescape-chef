default['cyclescape']['firewall']['rules'] = [
  'http' => {
    'port' => '80'
  },
  'https' => {
    'port' => '443'
  }
]

# Make sure apache listens for both http and https connections
default['apache']['listen_ports'] = %w(80 443)
default['cyclescape']['gem_folder'] = "#{default['brightbox-ruby']['version']}.0"
default['brightbox-ruby']['install_ruby_switch'] = true

