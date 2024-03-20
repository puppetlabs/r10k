require 'beaker-pe'

test_name 'CODEMGMT-20 - C48 - Install Puppet Enterprise'

step 'Install PE'
install_pe

step 'Stop puppet service to avoid running into existing agent runs'
on(hosts, puppet('resource service puppet ensure=stopped'))
