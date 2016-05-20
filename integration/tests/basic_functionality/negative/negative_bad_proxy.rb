require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'RK-110 - C88671 - Specify a bad proxy to r10k'

confine(:to, :platform => ['el', 'sles'])

#Init
master_platform = fact_on(master, 'osfamily')
r10k_fqp = get_r10k_fqp(master)

case master_platform
  when 'RedHat'
    pkg_manager = 'yum'
  when 'Suse'
    pkg_manager = 'zypper'
end

install_squid = "#{pkg_manager} install -y squid"
remove_squid = "#{pkg_manager} remove -y squid"

#Verification
proxy_hostname = "http://notarealhostname:3128"
error_regex = /Unable to connect to.*#{proxy_hostname}/i

#Teardown
teardown do
  step 'Remove puppetfile'
  on(master, 'rm -rf modules/')
  on(master, 'rm Puppetfile')

  step 'Remove Squid'
  on(master, puppet("apply -e 'service {'squid' : ensure => stopped}'"))
  on(master, remove_squid)

  step 'Remove proxy environment variable'
  master.delete_env_var('http_proxy', 'http://notarealhostname:3128')
end

step 'Install and configure squid proxy'
on(master, install_squid)
master.add_env_var('http_proxy', proxy_hostname)

step 'turn off the firewall'
on(master, puppet("apply -e 'service {'iptables' : ensure => stopped}'"))

step 'start squid proxy'
on(master, puppet("apply -e 'service {'squid' : ensure => running}'"))

#Tests
step 'make a puppetfile'
create_remote_file(master, "Puppetfile", 'mod "puppetlabs/motd"')

step 'Use a r10k puppetfile'
on(master, "#{r10k_fqp} puppetfile install", {:acceptable_exit_codes => [0,1,2]}) do |result|
  assert_match(error_regex, result.stderr, 'Did not see the expected error')
end
