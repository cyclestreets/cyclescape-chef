default['cyclescape']['firewall']['rules'] = [
  'http' => {
    'port' => '80'
  },
  'https' => {
    'port' => '443'
  }
]

# Make sure apache listens for both http and https connections
default['apache']['listen_ports'] = ['80', '443']
