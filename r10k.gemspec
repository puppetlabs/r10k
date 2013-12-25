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

  s.license  = 'Apache 2.0'

  s.add_dependency 'colored',   '>= 1.2'
  s.add_dependency 'cri',       '~> 2.4.0'
  s.add_dependency 'systemu',   '~> 2.5.2'
  s.add_dependency 'log4r',     '>= 1.1.10'
  s.add_dependency 'multi_json', '~> 1.8.2'

  s.add_dependency 'faraday',                       '~> 0.8.8'
  s.add_dependency 'faraday_middleware',            '~> 0.9.0'
  s.add_dependency 'faraday_middleware-multi_json', '~> 0.0.5'

  s.add_development_dependency 'rspec', '~> 2.14.0'
  s.add_development_dependency 'yard', '~> 0.8.7.3'

  s.files        = Dir.glob "{bin,lib,spec}/**/*"
  s.require_path = 'lib'
  s.bindir       = 'bin'
  s.executables  = 'r10k'

  s.test_files   = Dir.glob("spec/**/*_spec.rb")

  s.post_install_message = <<-EOD.gsub(/^ {4}/, '')
    NOTICE
    ======

    If you are upgrading from 1.1.0 and are using multiple sources, please read
    this. (If not, feel free to continue with your regularly scheduled day.)

    GH-48 (https://github.com/adrienthebo/r10k/issues/48) introduced the ability
    for environments to be prefixed with the source name so that multiple sources
    installed into the same directory would not overwrite each other. However
    prefixing was automatically enabled and would break existing setups where
    multiple sources were cloned into different directories.

    Because this introduced a breaking change, SemVer dictates that the automatic
    prefixing has to be rolled back. Prefixing can be enabled but always defaults
    to off. If you are relying on this behavior you will need to update your r10k.yaml
    to enable prefixing on a per-source basis.

    Please see the issue (https://github.com/adrienthebo/r10k/issues/48) for more
    information.
  EOD
end
