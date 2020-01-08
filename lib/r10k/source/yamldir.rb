class R10K::Source::Yamldir < R10K::Source::Hash
  R10K::Source.register(:yamldir, self)

  def initialize(name, basedir, options = {})
    config = options[:config] || '/etc/puppetlabs/r10k/environments.d'

    unless File.directory?(config)
      raise R10K::Deployment::Config::ConfigError, _("Error opening %{dir}: config must be a directory") % {dir: config}
    end

    unless File.readable?(config)
      raise R10K::Deployment::Config::ConfigError, _("Error opening %{dir}: permission denied") % {dir: config}
    end

    environment_data = Dir.glob(File.join(config, '*.yaml')).reduce({}) do |memo,path|
      name = File.basename(path, '.yaml')
      begin
        contents = ::YAML.load_file(path)
      rescue => e
        raise R10K::Deployment::Config::ConfigError, _("Error loading %{path}: %{err}") % {path: path, err: e.message}
      end
      memo.merge({name => contents })
    end

    # Set the environments key for the parent class to consume
    options[:environments] = environment_data

    # All we need to do is supply options with the :environments hash.
    # The R10K::Source::Hash parent class takes care of the rest.
    super(name, basedir, options)
  end
end
