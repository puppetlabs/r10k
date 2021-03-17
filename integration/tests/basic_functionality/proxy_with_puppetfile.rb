require 'git_utils'
require 'r10k_utils'
require 'master_manipulator'
test_name 'RK-110 - C87651 - Specify a proxy in an environment variable'

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
squid_log = "/var/log/squid/access.log"

#Verification
squid_log_regex = /CONNECT forgeapi.puppet.com:443/

#Teardown
teardown do
  step 'Remove puppetfile'
  on(master, 'rm -rf modules/')
  on(master, 'rm Puppetfile')

  step 'Remove Squid'
  on(master, puppet("apply -e 'service {'squid' : ensure => stopped}'"))
  on(master, remove_squid)

  step 'Remove proxy environment variable'
  master.delete_env_var('http_proxy', "http://#{master.hostname}:3128")
end

step 'Install and configure squid proxy'
on(master, install_squid)
master.add_env_var('http_proxy', "http://#{master.hostname}:3128")

step 'turn off the firewall'
on(master, puppet("apply -e 'service {'iptables' : ensure => stopped}'"))

step 'start squid proxy'
on(master, puppet("apply -e 'service {'squid' : ensure => running}'"))

#Tests
step 'make a puppetfile'
create_remote_file(master, "Puppetfile", 'mod "puppetlabs/motd"')

step 'Use a r10k puppetfile'
on(master, "#{r10k_fqp} puppetfile install")

step 'Read the squid logs'
on(master, "cat #{squid_log}") do |result|
  assert_match(squid_log_regex, result.stdout, 'Proxy logs did not indicate use of the proxy.')
end

