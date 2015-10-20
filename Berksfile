source "https://supermarket.chef.io"

cookbook 'build-essential', '~> 1.0.0'
cookbook 'apache2', '~> 2.0.0'
cookbook 'solr', '~> 0.5.0'
cookbook 'ufw', '~> 0.6.2'
local_cookbooks = %w(cyclescape brightbox-ruby cyclescape-backups cyclescape-user munin-plugins-rails
munin ntp passenger-gem postfix postgres ssl)
local_cookbooks.each do |local_cookbook|
  cookbook local_cookbook, path: "local-cookbooks/#{local_cookbook}"
end
