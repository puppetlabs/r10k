class R10K::Environment::Plain < R10K::Environment::WithModules

  R10K::Environment.register(:plain, self)

  def sync
    path.mkpath
  end

  def status
    :not_applicable
  end

  def signature
    'plain-default'
  end
end
