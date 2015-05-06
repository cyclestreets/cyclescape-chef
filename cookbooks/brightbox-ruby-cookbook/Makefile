default: bundle update_cookbooks foodcritic integration

bundle:
	bundle update

update_cookbooks:
	berks install
	berks update

foodcritic:
	bundle exec thor foodcritic:lint --epic-fail any

integration:
	bundle exec kitchen test -p --destroy=always

docs:
	bundle exec knife cookbook doc .
