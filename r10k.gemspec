lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'r10k/version'

Gem::Specification.new do |s|
  s.name        = "r10k"
  s.version     = R10K::VERSION
  s.platform    = Gem::Platform::RUBY

  s.authors     = "Adrien Thebo"
  s.email       = "adrien@somethingsinistral.net"
  s.homepage    = "https://github.com/puppetlabs/r10k"
  s.summary     = "Puppet environment and module deployment"
  s.description = <<-DESCRIPTION
    R10K provides a general purpose toolset for deploying Puppet environments and modules.
    It implements the Puppetfile format and provides a native implementation of Puppet
    dynamic environments.
  DESCRIPTION

  s.required_ruby_version = '>= 2.3.0'

  s.license  = 'Apache-2.0'

  s.add_dependency 'colored2',   '3.1.2'
  s.add_dependency 'cri', ['>= 2.15.10', '< 3.0.0']

  s.add_dependency 'log4r',     '1.1.10'
  s.add_dependency 'multi_json', '~> 1.10'

  s.add_dependency 'puppet_forge', '~> 2.3.0'

  s.add_dependency 'gettext-setup', '~>0.24'
  # These two pins narrow what is allowed by gettext-setup,
  # to preserver compatability with Ruby 2.4
  s.add_dependency 'fast_gettext', '~> 1.1.0'
  s.add_dependency 'gettext', ['>= 3.0.2', '< 3.3.0']

  s.add_development_dependency 'rspec', '~> 3.1'

  s.add_development_dependency 'rake'

  s.add_development_dependency 'yard', '~> 0.9.11'
  s.add_development_dependency 'minitar', '~> 0.9.0'

  s.files        = %x[git ls-files].split($/)
  s.require_path = 'lib'
  s.bindir       = 'bin'
  s.executables  = 'r10k'
end
