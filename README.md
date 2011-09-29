This is a collection of chef recipies that set up the server for the
Cyclestreets Toolkit. You might need to customise them for your own situation,
and pull requests are very welcome.

# Setup

This is designed to use chef-solo. First we need to grab this repository and
prep the cookbooks, then install chef-solo, then chef can take care of the rest.
The base system is ubuntu-server 11.04 so there's not much installed already.

    $ sudo apt-get install git
    $ git clone git@github.com:cyclestreets/toolkit-chef.git
    $ cd toolkit-chef/

(From this point on, we could just make a magic script to do the rest.)

First, we need to bundle up the cookbooks. This comes in handy later on.

    $ tar -czvf cookbooks.tgz cookbooks/

Now, we need to install chef. We're using chef 0.10 from the Opscode apt
repository.

[ Insert instructions from the opscode wiki here ]

Now we can run chef to take care of everything else. The node.json file
specifies which recipies we want to run

    $ cd ~
    $ sudo chef-solo -j toolkit-chef/node.json -r toolkit-chef/cookbooks.tgz
