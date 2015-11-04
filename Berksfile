source "https://supermarket.chef.io"

cookbook 'build-essential', '~> 1.0.0'
cookbook 'apache2', '~> 2.0.0'
cookbook 'solr', '~> 0.5.0'
cookbook 'ufw', '~> 0.7.4'
cookbook 'firewall', '< 2.0.0'
cookbook 'brightbox-ruby', '~> 1.2.1'
local_cookbooks = %w(cyclescape cyclescape-backups cyclescape-user munin-plugins-rails
munin ntp passenger-gem postfix postgres ssl)
local_cookbooks.each do |local_cookbook|
  cookbook local_cookbook, path: "local-cookbooks/#{local_cookbook}"
end
