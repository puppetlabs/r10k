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
  s.summary     = "Dynamic Puppet environments with Git"
  s.description = <<-DESCRIPTION
    R10K is an implementation of the Dynamic Puppet environments based on git repositories
    as described in http://puppetlabs.com/blog/git-workflow-and-puppet-environments/. It
    aggressively caches and tries to minimize network activity to ensure that interactive
    deployment is as fast as possible.
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
