require 'r10k/module_repository'
require 'r10k/version'

require 'faraday'
require 'faraday_middleware/multi_json'

class R10K::ModuleRepository::Forge

  # @!attribute [r] forge
  #   @return [String] The forge hostname to use for requests
  attr_reader :forge

  # @!attribute [r] :conn
  #   @api private
  #   @return [Faraday]
  attr_reader :conn

  def initialize(forge = 'forge.puppetlabs.com')
    @forge = forge
    @conn = Faraday.new(
      :url => "https://#{@forge}",
      :user_agent => "Ruby/r10k #{R10K::VERSION}"
    ) do |builder|
      builder.adapter Faraday.default_adapter
      builder.request :multi_json
      builder.response :multi_json
    end
  end

  # Query for all published versions of a module
  #
  # @example
  #   forge = R10K::ModuleRepository::Forge.new
  #   forge.versions('adrien/boolean')
  #   #=> ["0.9.0-rc1", "0.9.0", "1.0.0", "1.0.1"]
  #
  # @param module_name [String] The fully qualified module name
  # @return [Array<String>] All published versions of the given module
  def versions(module_name)
    resp = @conn.get("/api/v1/releases.json", {'module' => module_name})

    body = resp.body

    body[module_name].map do |version_info|
      version_info['version']
    end
  end

  # Query for the newest published version of a module
  #
  # @example
  #   forge = R10K::ModuleRepository::Forge.new
  #   forge.latest_version('adrien/boolean')
  #   #=> "1.0.1"
  #
  # @param module_name [String] The fully qualified module name
  # @return [String] The latest published version of the given module
  def latest_version(module_name)
    versions(module_name).last
  end
end
