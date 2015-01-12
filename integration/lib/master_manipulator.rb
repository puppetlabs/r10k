# Create a "site.pp" file with file bucket enabled. Also, allow
# the creation of a custom node definition or use the 'default'
# node definition.
#
# ==== Attributes
#
# * +master_certname+ - Certificate name of Puppet master.
# * +manifest+ - A Puppet manifest to inject into the node definition.
# * +node_def_name+ - A node definition pattern or name.
#
# ==== Returns
#
# +string+ - A combined manifest with node definition containing input manifest
#
# ==== Examples
#
# site_pp = create_site_pp("puppetmaster", '', node_def_name='agent')
def create_site_pp(master_certname, manifest='', node_def_name='default')
  default_def = <<-MANIFEST
node default {
}
MANIFEST

  node_def = <<-MANIFEST
node #{node_def_name} {

#{manifest}
}
MANIFEST

  if node_def_name != 'default'
    node_def = "#{default_def}\n#{node_def}"
  end

  site_pp = <<-MANIFEST
filebucket { 'main':
  server => '#{master_certname}',
  path   => false,
}

File { backup => 'main' }

#{node_def}
MANIFEST

  return site_pp
end

# Read a Puppet manifest file and inject the content into a
# "default" node definition. (Used mostly to overide site.pp)
#
# ==== Attributes
#
# * +manifest_path+ - The file path to target manifest.
# * +master_certname+ - Certificate name of Puppet master.
#
# ==== Returns
#
# +string+ - A combined manifest with node definition containg input manifest
#
# ==== Examples
#
# site_pp = create_node_manifest("/tmp/test.pp", "master")
def create_node_manifest(manifest_path, master_certname, node_def_name='default')
  manifest = File.read(manifest_path)

  site_pp = <<-MANIFEST
filebucket { 'main':
  server => '#{master_certname}',
  path   => false,
}

File { backup => 'main' }

node default {

#{manifest}
}
MANIFEST

  return site_pp
end

# Set mode, owner and group on a remote path.
#
# ==== Attributes
#
# * +host+ - The remote host containing the target path.
# * +path+ - The path to set mode, user and group upon.
# * +mode+ - The desired mode to set on the path in as a string.
# * +owner+ - The owner to set on the path. (Puppet user if not specified.)
# * +group+ - The group to set on the path. (Puppet group if not specified.)
#
# ==== Returns
#
# nil
#
# ==== Examples
#
# set_perms_on_remote(master, "/tmp/test/site.pp", "777")
def set_perms_on_remote(host, path, mode, owner=nil, group=nil)
  if (owner.nil?)
    owner = on(host, puppet('config', 'print', 'user')).stdout.rstrip
  end

  if (group.nil?)
    group = on(host, puppet('config', 'print', 'group')).stdout.rstrip
  end

  on(host, "chmod -R #{mode} #{path}")
  on(host, "chown -R #{owner}:#{group} #{path}")
end

# Inject temporary "site.pp" onto target host. This will also create
# a "modules" folder in the target remote directory.
#
# ==== Attributes
#
# * +master+ - The target master for injection.
# * +site_pp_path+ - A path on the remote host into which the site.pp will be injected.
# * +manifest+ - The manifest content to inject into "site.pp" to the host target path.
#
# ==== Returns
#
# nil
#
# ==== Examples
#
# site_pp = inject_site_pp(master, "/tmp/test/site.pp", manifest)
def inject_site_pp(master, site_pp_path, manifest)
  site_pp_dir = File.dirname(site_pp_path)
  create_remote_file(master, site_pp_path, manifest)

  set_perms_on_remote(master, site_pp_dir, "777")
end

# Create a temporary directory environment and inject a "site.pp" for the target environment.
#
# ==== Attributes
#
# * +master+ - The master on which to create a new Puppet environment.
# * +env_root_path+ - The base path on the master that contains all environments.
# * +env_seed_name+ - The seed name to use for generating an environment name.
# * +manifest+ - The manifest content to inject into "site.pp" of the newly created environment.
#
# ==== Returns
#
# +string+ - The environment name that was generated.
#
# ==== Examples
#
# temp_env_name = create_temp_dir_env(master, "/tmp/test/site.pp", "stuff", manifest)
def create_temp_dir_env(master, env_root_path, env_seed_name, manifest)
  env_name = "#{env_seed_name}" + rand(36**16).to_s(36)
  env_path = "#{env_root_path}/#{env_name}"
  env_site_pp_path = "#{env_path}/manifests/site.pp"

  on(master, "mkdir -p #{env_path}/manifests #{env_path}/modules")
  set_perms_on_remote(master, env_path, "777")

  inject_site_pp(master, env_site_pp_path, manifest)

  return env_name
end

# Restart the puppet server and wait for it to come back up
# ==== Attributes
# *+host+ - the host that this should operate on
# *+opts+ - an options hash - not required
#   *+:timeout+ - the amount of time in seconds to wait for success
#   *+:frequency+ - The time to wait between retries
#
# Raises a standard error if the wait is uncessfull
#
# ==== Example
# restart_puppet_server(master)
# restart_puppet_server(master, {:time_out => 200, :frequency => 10})
def restart_puppet_server(host, opts = {})

  on(host, "puppet resource service pe-puppetserver ensure=stopped")
  on(host, "puppet resource service pe-puppetserver ensure=running")
  masterHostName = on(host, "hostname").stdout.chomp
  opts[:time_out] ||= 100
  opts[:frequency] ||= 5
  i = 0

  # -k to ignore HTTPS error that isn't relevant to us
  curl_call = "-I -k https://#{masterHostName}:8140/production/certificate_statuses/all"

  while i < opts[:time_out] do
    sleep opts[:frequency]
    i += 1
    exit_code = curl_on(host, curl_call, :acceptable_exit_codes => [0,1,7]).exit_code

    # Exit code 7 is "connection refused"
    if exit_code != '7'
      sleep 20
      puts 'Restarting the Puppet Server was successful!'
      return
    end
  end

  raise StandardError, 'Attempting to restart the puppet server was not successful in the time alloted.'

end
