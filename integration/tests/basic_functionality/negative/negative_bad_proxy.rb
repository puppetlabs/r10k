require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'RK-110 - C88671 - Specify a bad proxy to r10k'

confine(:to, :platform => ['el', 'sles'])

#Init
master_platform = fact_on(master, 'os.family')
r10k_fqp = get_r10k_fqp(master)

#Verification
proxy_hostname = "http://notarealhostname:3128"
error_regex = /Unable to connect to.*#{proxy_hostname}/i

#Teardown
teardown do
  step 'Remove puppetfile'
  on(master, 'rm -rf modules/')
  on(master, 'rm Puppetfile')
end

step 'turn off the firewall'
on(master, puppet("apply -e 'service {'iptables' : ensure => stopped}'"))

#Tests
step 'make a puppetfile'
create_remote_file(master, "Puppetfile", 'mod "puppetlabs/motd"')

step 'Use a r10k puppetfile'
on(master, "#{r10k_fqp} puppetfile install", {:acceptable_exit_codes => [0,1,2], :environment => {"http_proxy" => proxy_hostname}}) do |result|
  assert(result.exit_code == 1, 'The expected exit code was not observed.')
  assert_match(error_regex, result.stderr, 'Did not see the expected error')
end
