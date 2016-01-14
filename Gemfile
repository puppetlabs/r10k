source 'https://rubygems.org'

gemspec

group :extra do
  gem 'rugged', '~> 0.21.4', :platforms => :ruby
  gem 'rjgit', :git => 'https://github.com/andersonmills/rjgit.git', :branch => 'add_git_dir_to_repo', :platforms => :jruby
#  gem 'rjgit', '~> 4.1.1.0', :platforms => :jruby
end

group :development do
  gem 'simplecov', '~> 0.9.1'
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
