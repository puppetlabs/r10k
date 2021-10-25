class R10K::Environment::Bare < R10K::Environment::Plain

  R10K::Environment.register(:bare, self)

  def initialize(name, basedir, dirname, options = {})
    logger.warn _('"bare" environment type is deprecated; please use "plain" instead (environment: %{name})') % {name: name}
    super
  end

  def signature
    'bare-default'
  end
end
