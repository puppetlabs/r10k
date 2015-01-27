# Verify that a pristine "production" environment exists on the master.
# (And only the "production" environment!)
#
# ==== Attributes
#
# * +host+ - The Puppet master on which to verify the "production" environment.
#
# ==== Returns
#
# +nil+
#
# ==== Examples
#
# verify_production_environment(master)
def verify_production_environment(master)
  environment_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
  prod_env_md5sum_path = File.join(environment_path, 'production', 'manifests', '.site_pp.md5')

  #Verify MD5 sum of "site.pp"
  on(master, "md5sum -c #{prod_env_md5sum_path}")

  #Verify that "production" is the only environment available.
  on(master, "test `ls #{environment_path} | wc -l` -eq 1")
  on(master, "ls #{environment_path} | grep \"production\"")
end
