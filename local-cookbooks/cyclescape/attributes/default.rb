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
default["brightbox-ruby"]["version"] = "2.3"
default['brightbox-ruby']['default_action'] = :install
default['brightbox-ruby']['install_ruby_switch'] = true
default['brightbox-ruby']['rubygems_version'] = '2.6.13'
default['java']['jdk_version'] = 7

default['apache']['prefork']['startservers'] = 4
default['passenger']['ruby_bin'] = "/usr/bin/ruby#{default['brightbox-ruby']['version']}"
default['passenger']['version'] = '5.1.11'
default['passenger']['root_path'] = "#{languages['ruby']['gems_dir']}/gems/passenger-#{node['passenger']['version']}"
default['nodejs']['version'] = '6'
default['nodejs']['install_repo'] = true
