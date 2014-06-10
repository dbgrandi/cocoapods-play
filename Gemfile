source 'https://rubygems.org'

# Specify your gem's dependencies in cocoapods-play.gemspec
gemspec

group :development do
  gem 'cocoapods',    :git => "https://github.com/CocoaPods/CocoaPods.git", :branch => 'master'
  gem 'claide',       :git => "https://github.com/CocoaPods/CLAide.git", :branch => 'master'
  gem 'bacon'
  gem 'coveralls', :require => false
  gem 'mocha-on-bacon'
  gem 'prettybacon'
  gem 'webmock'
  if RUBY_VERSION >= '1.9.3'
    gem 'rubocop'
  end
end
