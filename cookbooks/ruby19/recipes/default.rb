#
# Cookbook Name:: ruby19
# Recipe:: default
#
# Copyright 2011, Cyclestreets Ltd

# I hate having multiple rubies, but I hate having rvm even more

# Due to the joys of debian package names, these are actually 1.9.2
["ruby1.9.1", "irb1.9.1", "ri1.9.1", "ruby1.9.1-dev"].each do |p|
  package p
end

script "configure ruby in update-alternatives" do
  interpreter "bash"
  code <<-EOH
    update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.8 400 \
                        --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz \
                                      /usr/share/man/man1/ruby.1.8.gz \
                        --slave   /usr/bin/ri ri /usr/bin/ri1.8 \
                        --slave   /usr/bin/irb irb /usr/bin/irb1.8

    # install ruby1.9 & friends with priority 500 i.e. higher
    update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 500 \
                        --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz \
                                      /usr/share/man/man1/ruby.1.9.1.gz \
                        --slave   /usr/bin/ri ri /usr/bin/ri1.9.1 \
                        --slave   /usr/bin/irb irb /usr/bin/irb1.9.1
  EOH
end