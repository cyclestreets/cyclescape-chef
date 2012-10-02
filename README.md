This is a collection of chef recipies that set up the server for the
Cyclestreets Toolkit. You might need to customise them for your own situation,
and pull requests are very welcome.

# Setup

This is designed to use chef-solo. First we need to grab this repository and
prep the cookbooks, then install chef-solo, then chef can take care of the rest.
The base system is ubuntu-server 11.04 so there's not much installed already.

    $ sudo apt-get install git
    $ git clone https://github.com/cyclestreets/toolkit-chef.git
    $ cd toolkit-chef/

(From this point on, we could just make a magic script to do the rest.)

Now, we need to install chef. We're using chef 0.10 from the Opscode apt
repository.

    echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
    sudo mkdir -p /etc/apt/trusted.gpg.d
    gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
    gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
    sudo apt-get update
    sudo apt-get install opscode-keyring # permanent upgradeable keyring
    sudo apt-get upgrade
    sudo apt-get install chef

When you are prompted for the server url, enter "none"

# Databags

If you are running this recipe with chef-solo, you need to
create the secrets databag in /etc. Unfortunately chef loads databags
before running any recipies, so it needs to be done by hand.

    sudo mkdir -p /etc/chef/databags/secrets

Then copy the example file over

    sudo cp path/to/cookbooks/toolkit/templates/default/mailbox.json /etc/chef/databags/secrets/
    sudo chmod 0600 /etc/chef/databags/secrets/mailbox.json

Then fill in the real values

    sudo nano /etc/chef/databags/secrets/mailbox.json

Then run chef as normal. If you are running against a chef-server,
then create the databag from the .json example using knife.

N.B. When you set up the mailbox values, and run chef (below), it'll
start processing emails from that mailbox with no further configuration
change. It's worth being cautious when setting up failover servers,
for example.

# Running chef

At this point, chef can take care of everything else.

    $ cd ~
    $ sudo chef-solo -c toolkit-chef/solo.rb -j toolkit-chef/node.json

It's easy to run chef again - for example, in order to deploy the latest version.

# Updating the cookbooks

If the cookbooks themselves change - for example, if you add another package,
or change the contents of one of the templates, you'll need to update and rebundle
the cookbooks, then run chef-solo

    $ cd toolkit-chef
    $ git pull
    $ cd ~
    $ sudo chef-solo -c toolkit-chef/solo.rb -j toolkit-chef/node.json
