require 'fileutils'
root = File.expand_path(File.dirname(__FILE__))
silence_deprecation_warnings %w{deploy_resource}
cookbook_path root + '/cookbooks'
data_bag_path '/etc/chef/databags'
log_level :info
log_location '/var/log/chef/solo.log'
FileUtils.mkdir_p File.dirname(log_location)
verbose_logging true
