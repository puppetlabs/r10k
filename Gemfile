source 'https://rubygems.org'

gemspec

group(:system) do
  gem 'rspec-system', '~> 2.8.0'
  gem 'rspec-system-serverspec', '~> 2.0.1'
  gem 'vagrant', :git => 'git://github.com/mitchellh/vagrant', :tag => 'v1.4.1'
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
