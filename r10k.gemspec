lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'r10k/version'

Gem::Specification.new do |s|
  s.name        = "r10k"
  s.version     = R10K::VERSION
  s.platform    = Gem::Platform::RUBY

  s.authors     = "Adrien Thebo"
  s.email       = "adrien@somethingsinistral.net"
  s.homepage    = "http://github.com/adrienthebo/r10k"
  s.summary     = "Puppet environment and module deployment"
  s.description = <<-DESCRIPTION
    R10K provides a general purpose toolset for deploying Puppet environments and modules.
    It implements the Puppetfile format and provides a native implementation of Puppet
    dynamic environments.
  DESCRIPTION

  s.license  = 'Apache-2.0'

  s.add_dependency 'colored',   '1.2'
  s.add_dependency 'cri',       '~> 2.6.1'

  s.add_dependency 'log4r',     '1.1.10'
  s.add_dependency 'multi_json', '~> 1.10'
  s.add_dependency 'json_pure',  '~> 1.8'

  s.add_dependency 'faraday',                       '~> 0.9.0'
  s.add_dependency 'faraday_middleware',            '~> 0.9.0'
  s.add_dependency 'faraday_middleware-multi_json', '~> 0.0.6'

  s.add_dependency 'semantic_puppet', '~> 0.1.0'

  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'vcr',   '~> 2.9'

  s.add_development_dependency 'minitar'

  s.add_development_dependency 'yard', '~> 0.8.7.3'

  s.files        = %x[git ls-files].split($/)
  s.require_path = 'lib'
  s.bindir       = 'bin'
  s.executables  = 'r10k'

  s.test_files   = Dir.glob("spec/**/*_spec.rb")
end
