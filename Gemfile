source ENV['GEM_SOURCE'] || 'https://rubygems.org'
gemspec

group :extra do
  gem 'rugged', '>= 0.24.0', '< 0.24.6', :platforms => :ruby
end

group :development do
  gem 'simplecov', '~> 0.9.1'
  gem 'ruby-prof', :platforms => :ruby
  gem 'pry'
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
