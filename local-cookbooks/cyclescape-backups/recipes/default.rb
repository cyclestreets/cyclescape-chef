#
# Cookbook Name:: cyclescape-backups
# Recipe:: default
#
# Copyright 2019, Cyclestreets Ltd

backup_directory = '/websites/cyclescape/backup'
shared = 'cyclescapeShared.tar.bz2'
recent = 'cyclescapeSharedRecent.tar.bz2'
dbdump = 'cyclescapeDB.sql.gz'
anon_dbdump = 'cyclescapeDB.anon.sql.gz'
database = 'cyclescape_production'

directory backup_directory do
  owner 'cyclescape'
  group 'cyclescape'
  recursive true
end

# Add backup cron job

template 'backup script' do
  owner 'cyclescape'
  group 'cyclescape'
  path File.join(backup_directory, 'run-backups.sh')
  source 'run-backups.sh.erb'
  variables(
    backup_directory: backup_directory,
    shared_filename: File.join(backup_directory, shared),
    recent_filename: File.join(backup_directory, recent),
    dbdump_filename: File.join(backup_directory, dbdump),
    anon_dbdump_filename: File.join(backup_directory, anon_dbdump),
    database: database
  )
end

cron 'shared-backup' do
  minute '37'
  hour '1'
  mailto data_bag_item("secrets", "mailbox")["error_email"]
  user 'cyclescape'
  command "/bin/bash #{File.join(backup_directory, 'run-backups.sh')} >> #{File.join(backup_directory, 'run-backups.log')} 2>&1"
end
