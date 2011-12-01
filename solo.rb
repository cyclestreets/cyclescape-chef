root = File.expand_path(File.dirname(__FILE__))

cookbook_path root + '/cookbooks'
data_bag_path '/etc/chef/databags'
log_level :debug
log_location '/var/log/chef/solo.log'
verbose_logging true
