# The apache2 cookbook depends on iptables, but we really
# don't want it to run since it will almost certainly mess
# up the ufw rules.

fail 'This dummy iptables recipe should not be run'
