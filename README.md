This is a collection of chef recipies that set up the server for Cyclescape.
You might need to customise them for your own situation, and pull requests
are very welcome.

# Setup

This is designed to use chef-solo. First we need to grab this repository and
prep the cookbooks, then install chef-solo, then chef can take care of the rest.
The base system is ubuntu-server 20.04 LTS or 18.04 LTS so there's not much
installed already.

    cd ~
    sudo apt-get -y install git
    git clone https://github.com/cyclestreets/cyclescape-chef.git
    sudo mv cyclescape-chef /opt
    cd /opt/cyclescape-chef/

(From this point on, we could just make a magic script to do the rest.)

Now, we need to install chef development kit can (full details from https://downloads.chef.io/chef-dk/ubuntu/)

    curl -o chefdk.deb https://packages.chef.io/files/stable/chefdk/2.5.13/ubuntu/20.04/chefdk_2.5.13-1_amd64.deb
    sudo dpkg -i chefdk.deb

To test on a development machine this it is possible to use vagrant with VirtualBox

```sh
sudo apt install vagrant virtualbox-5.1
vagrant plugin install vagrant-berkshelf
vagrant up
```

Note on debian https://wiki.debian.org/VirtualBox#Installation_of_non-free_edition

# Databags

If you are running this recipe with chef-solo, you need to
create the secrets databag in /etc. Unfortunately chef loads databags
before running any recipies, so it needs to be done by hand.

    sudo mkdir -p /etc/chef/databags/
    sudo mkdir -p /var/log/chef/

Then copy the example file over:

    sudo cp -r data-bags/* /etc/chef/databags/
    sudo chmod 0600 /etc/chef/databags/secrets/*

Then fill in the real values, to add the details of a mailbox you have set up on a
third-party server (Cyclescape will retrieve mail periodically from this).

    sudo nano /etc/chef/databags/secrets/*

Then run chef as normal (described below). If you are running against a chef-server,
then create the databag from the .json example using knife.

N.B. When you set up the mailbox values, and run chef (below), it'll
start processing emails from that mailbox with no further configuration
change. It's worth being cautious when setting up failover servers,
for example. In that scenario, while setting up, don't put the credentials in.
Chef will work, but there will be a slightly annoyed daemon who can't fetch any
mail. When you want to run the site live, edit the credentials and re-run chef
and it should all kick into life.

# SSL certificates

Apache is configured to require SSL certificates. Obviously the actual production signing key
can't be included in these chef scripts, otherwise anyone can set up a fake https server.

To setup SSL, overwrite the /etc/apache2/ssl/cyclescape-org.ssl.crt and cyclescape-org.ssl.nopassword.key
with the actual copies (held elsewhere).

# Running chef

At this point, chef can take care of everything else.

    cd /opt/cyclescape-chef/
    sudo berks install
    sudo berks vendor cookbooks/
    sudo chef-solo -c solo.rb -j node.json

If the chef run reports that it has failed, check the log file at /var/log/chef/solo.log .

If running a test in a VM, ensure you have allocated enough memory. The installation is known to fail with, for instance, only 512M allocated.

It's easy to run chef again - for example, in order to deploy the latest version.

# Updating the cookbooks

If the cookbooks themselves change - for example, if you add another package,
or change the contents of one of the templates, you'll need to update and rebundle
the cookbooks, then run chef-solo:

    cd /opt/cyclescape-chef/
    git pull
    sudo berks install
    sudo berks vendor cookbooks/
    sudo chef-solo -c solo.rb -j node.json
