class R10K::Environment::Bare < R10K::Environment::WithModules

  R10K::Environment.register(:bare, self)

  def sync
    path.mkpath
  end

  def status
    :not_applicable
  end

  def signature
    'bare-default'
  end
end
