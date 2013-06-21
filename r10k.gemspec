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

  s.add_dependency 'colored',   '>= 1.2'
  s.add_dependency 'cri',       '~> 2.3.0'
  s.add_dependency 'systemu',   '~> 2.5.2'
  s.add_dependency 'log4r',     '>= 1.1.10'
  s.add_dependency 'json_pure'

  s.add_development_dependency 'rspec', '~> 2.10.0'
  s.add_development_dependency 'mocha', '~> 0.10.5'

  s.files        = Dir.glob "{bin,lib}/**/*"
  s.require_path = 'lib'
  s.bindir       = 'bin'
  s.executables  = 'r10k'

  s.test_files   = Dir.glob("spec/**/*_spec.rb")
end
