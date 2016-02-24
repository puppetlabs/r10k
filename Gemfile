source 'https://rubygems.org'

gemspec

  gem 'puppet_forge', :git => 'https://github.com/puppetlabs/forge-ruby', :branch => 'master'
group :extra do
  gem 'rugged', '~> 0.21.4', :platforms => :ruby
  gem 'rjgit', :git => 'https://github.com/andersonmills/rjgit.git', :branch => 'master', :platforms => :jruby
#  gem 'rjgit', :path => '/Users/anderson/puppet/src/rjgit', :platforms => :jruby
#  gem 'rjgit', '~> 4.1.1.0', :platforms => :jruby
end

group :development do
  gem 'simplecov', '~> 0.9.1'
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
