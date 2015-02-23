#
# Cookbook Name:: rbenv
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd


user_name = 'cyclescape'
ruby_version = '2.1.5'
# create .bash_profile file
cookbook_file "/home/#{cyclescape}/.bash_profile" do
  source "bash_profile"
  mode 0644
  owner cyclescape
end

# install rbenv
bash 'install rbenv' do
  user cyclescape
  cwd "/home/#{cyclescape}"
  code <<-EOH
    export HOME=/home/#{cyclescape}
    curl -L https://raw.github.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash
  EOH
  not_if { File.exists?("/home/#{cyclescape}/.rbenv/bin/rbenv") }
end

# install ruby
version_path = "/home/#{cyclescape}/.rbenv/version"
bash 'install ruby' do
  user cyclescape
  cwd "/home/#{cyclescape}"
  code <<-EOH
    export HOME=/home/#{cyclescape}
    export RBENV_ROOT="${HOME}/.rbenv"
    export PATH="${RBENV_ROOT}/bin:${PATH}"
    rbenv init -

    rbenv install #{ruby_version}
    rbenv global #{ruby_version}
    echo 'gem: -–no-ri -–no-rdoc' > .gemrc
    .rbenv/bin/rbenv exec gem install bundler
    rbenv rehash
  EOH
  not_if { File.exists?(version_path) && `cat #{version_path}`.chomp.split[0] == node['ruby']['version'] }
end

