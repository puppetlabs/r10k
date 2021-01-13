require 'beaker-pe'

test_name 'CODEMGMT-20 - C48 - Install Puppet Enterprise'

step 'Install PE'
install_pe

hosts.each do |host|
  stop_agent_on(host)
end
