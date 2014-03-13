This is a collection of chef recipies that set up the server for the
Cyclestreets Toolkit. You might need to customise them for your own situation,
and pull requests are very welcome.

# Setup

This is designed to use chef-solo. First we need to grab this repository and
prep the cookbooks, then install chef-solo, then chef can take care of the rest.
The base system is ubuntu-server 12.04 LTS so there's not much installed already.

    cd ~
    sudo apt-get install git
    git clone https://github.com/cyclestreets/toolkit-chef.git
    sudo mv toolkit-chef /opt
    cd /opt/toolkit-chef/

(From this point on, we could just make a magic script to do the rest.)

Now, we need to install chef. We're using chef 11.10 with the ombnibus (i.e. embedded
ruby) package

    wget https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef_11.10.4-1.ubuntu.12.04_amd64.deb
    sudo dpkg -i chef_11.10.4-1.ubuntu.12.04_amd64.deb


When you are prompted for the server url, enter "none"

# Databags

If you are running this recipe with chef-solo, you need to
create the secrets databag in /etc. Unfortunately chef loads databags
before running any recipies, so it needs to be done by hand.

    sudo mkdir -p /etc/chef/databags/secrets

Then copy the example file over:

    sudo cp cookbooks/toolkit/templates/default/mailbox.json /etc/chef/databags/secrets/
    sudo chmod 0600 /etc/chef/databags/secrets/mailbox.json

Then fill in the real values, to add the details of a mailbox you have set up on a
third-party server (Cyclescape will retrieve mail periodically from this).

    sudo nano /etc/chef/databags/secrets/mailbox.json

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

    $ cd /opt/
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
