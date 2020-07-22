# This class implements an environment source based on recieving a hash of
# environments
#
# @since 3.4.0
#
# DESCRIPTION
#
# This class implements environments defined by a hash having the following
# schema:
#
#     ---
#     type: object
#     additionalProperties:
#       type: object
#       properties:
#         type:
#           type: string
#         basedir:
#           type: string
#         modules:
#           type: object
#           additionalProperties:
#             type: object
#         moduledir:
#           type: string
#       additionalProperties:
#         type: string
#
# The top-level keys in the hash are environment names. Keys in individual
# environments should be the same as those which would be given to define a
# single source in r10k.yaml. Additionally, the "modules" key (and moduledir)
# can be used to designate module content for the environment, independent of
# the base source parameters.
#
# Example:
#
#     ---
#     production:
#       type: git
#       remote: 'https://github.com/reidmv/control-repo.git'
#       ref: '1.0.0'
#       modules:
#         geoffwilliams-r_profile: '1.1.0'
#         geoffwilliams-r_role: '2.0.0'
#
#     development:
#       type: git
#       remote: 'https://github.com/reidmv/control-repo.git'
#       ref: 'master'
#       modules:
#         geoffwilliams-r_profile: '1.1.0'
#         geoffwilliams-r_role: '2.0.0'
#
# USAGE
#
# The following is an example implementation class showing how to use the
# R10K::Source::Hash abstract base class. Assume an r10k.yaml file such as:
#
#     ---
#     sources:
#       proof-of-concept:
#         type: demo
#         basedir: '/etc/puppetlabs/code/environments'
#
# Class implementation:
#
#     class R10K::Source::Demo < R10K::Source::Hash
#       R10K::Source.register(:demo, self)
#
#       def initialize(name, basedir, options = {})
#         # This is just a demo class, so we hard-code an example :environments
#         # hash here. In a real class, we might do something here such as
#         # perform an API call to retrieve an :environments hash.
#         options[:environments] = {
#           'production' => {
#             'remote'  => 'https://git.example.com/puppet/control-repo.git',
#             'ref'     => 'release-141',
#             'modules' => {
#               'puppetlabs-stdlib' => '6.1.0',
#               'puppetlabs-ntp' => '8.1.0',
#               'example-myapp1' => {
#                 'git' => 'https://git.example.com/puppet/example-myapp1.git',
#                 'ref' => 'v1.3.0',
#               },
#             },
#           },
#           'development' => {
#             'remote'  => 'https://git.example.com/puppet/control-repo.git',
#             'ref'     => 'master',
#             'modules' => {
#               'puppetlabs-stdlib' => '6.1.0',
#               'puppetlabs-ntp' => '8.1.0',
#               'example-myapp1' => {
#                 'git' => 'https://git.example.com/puppet/example-myapp1.git',
#                 'ref' => 'v1.3.1',
#               },
#             },
#           },
#         }
#
#         # All we need to do is supply options with the :environments hash.
#         # The R10K::Source::Hash parent class takes care of the rest.
#         super(name, basedir, options)
#       end
#     end
#
# Example output:
#
#     [root@master:~] % r10k deploy environment production -pv
#     INFO     -> Using Puppetfile '/etc/puppetlabs/code/environments/production/Puppetfile'
#     INFO     -> Using Puppetfile '/etc/puppetlabs/code/environments/development/Puppetfile'
#     INFO     -> Deploying environment /etc/puppetlabs/code/environments/production
#     INFO     -> Environment production is now at 74ea2e05bba796918e4ff1803018c526337ef5f3
#     INFO     -> Deploying Environment content /etc/puppetlabs/code/environments/production/modules/stdlib
#     INFO     -> Deploying Environment content /etc/puppetlabs/code/environments/production/modules/ntp
#     INFO     -> Deploying Environment content /etc/puppetlabs/code/environments/production/modules/myapp1
#     INFO     -> Deploying Puppetfile content /etc/puppetlabs/code/environments/production/modules/ruby_task_helper
#     INFO     -> Deploying Puppetfile content /etc/puppetlabs/code/environments/production/modules/bolt_shim
#     INFO     -> Deploying Puppetfile content /etc/puppetlabs/code/environments/production/modules/apply_helpers
#
class R10K::Source::Hash < R10K::Source::Base

  include R10K::Logging

  # @param hash [Hash] A hash to validate.
  # @return [Boolean] False if the hash is obviously invalid. A true return
  #   means _maybe_ it's valid.
  def self.valid_environments_hash?(hash)
    # TODO: more robust schema valiation
    hash.is_a?(Hash)
  end

  # @param name [String] The identifier for this source.
  # @param basedir [String] The base directory where the generated environments will be created.
  # @param options [Hash] An additional set of options for this source. The
  #   semantics of this hash may depend on the source implementation.
  #
  # @option options [Boolean, String] :prefix If a String this becomes the prefix.
  #   If true, will use the source name as the prefix. All sources should respect this option.
  #   Defaults to false for no environment prefix.
  # @option options [Hash] :environments The hash definition of environments
  def initialize(name, basedir, options = {})
    super(name, basedir, options)
  end

  # Set the environment hash for the source. The environment hash is what the
  # source uses to generate enviroments.
  # @param hash [Hash] The hash to sanitize and use as the source's environments.
  #   Should be formatted for use with R10K::Environment#from_hash.
  def set_environments_hash(hash)
    @environments_hash = hash.reduce({}) do |memo,(name,opts)|
      R10K::Util::SymbolizeKeys.symbolize_keys!(opts)
      memo.merge({ 
        name => opts.merge({
          :basedir => @basedir,
          :dirname => R10K::Environment::Name.new(name, {prefix: @prefix, source: @name}).dirname
        })
      })
    end
  end

  # Return the sanitized environments hash for this source. The environments
  # hash should contain objects formatted for use with R10K::Environment#from_hash.
  # If the hash does not exist it will be built based on @options.
  def environments_hash
    @environments_hash ||= set_environments_hash(@options.fetch(:environments, {}))
  end

  def environments
    @environments ||= environments_hash.map do |name, hash|
      R10K::Environment.from_hash(name, hash)
    end
  end

  # List all environments that should exist in the basedir for this source
  # @note This is required by {R10K::Util::Basedir}
  # @return [Array<String>]
  def desired_contents
    environments.map {|env| env.dirname }
  end

end
