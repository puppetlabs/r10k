test_name 'CODEMGMT-62 - C63199 - Install Utilities for r10k Integration Testing'

#Init
filebucket_path = '/opt/filebucket'
filebucket_script_path = '/etc/profile.d/filebucket_path.sh'

filebucket_script = <<-SCRIPT
#!/bin/bash
export PATH="${PATH}:#{filebucket_path}"
SCRIPT

step 'Install "filebucket" File Generator'
create_remote_file(master, filebucket_script_path, filebucket_script)
on(master, "git clone git://github.com/cowofevil/filebucket.git #{filebucket_path}")

on(master, "chmod 755 #{filebucket_script_path}")
on(master, "chmod 755 #{filebucket_path}/filebucketapp.py")
