source "https://supermarket.chef.io"

cookbook 'build-essential', '~> 8.0.0'
cookbook 'apache2', '~> 5'
cookbook 'java', '~> 4.2.0'
cookbook 'ufw', '~> 3.2.1'
cookbook 'firewall', '~> 2'
cookbook 'ruby_build', '= 1.3.0' # beyond requires chef 15
cookbook 'git', '= 10.1.0' # beyond requires chef 15
cookbook 'passenger_apache2'
cookbook 'nodejs', '~> 5.0.0'
cookbook 'deploy_resource'
cookbook 'exim4-light'

local_cookbooks = %w(cyclescape cyclescape-backups cyclescape-user munin-plugins-rails
munin postgres ssl letsencrypt)
local_cookbooks.each do |local_cookbook|
  cookbook local_cookbook, path: "local-cookbooks/#{local_cookbook}"
end
