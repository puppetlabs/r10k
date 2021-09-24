class R10K::Source::Yaml < R10K::Source::Hash
  R10K::Source.register(:yaml, self)

  def initialize(name, basedir, options = {})
    config = options[:config] || '/etc/puppetlabs/r10k/environments.yaml'

    begin
      contents = ::YAML.load_file(config)
    rescue => e
      raise R10K::ConfigError, _("Couldn't open environments file %{file}: %{err}") % {file: config, err: e.message}
    end

    # Set the environments key for the parent class to consume
    options[:environments] = contents

    # All we need to do is supply options with the :environments hash.
    # The R10K::Source::Hash parent class takes care of the rest.
    super(name, basedir, options)
  end
end
