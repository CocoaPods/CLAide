source 'https://rubygems.org'

gem 'rake'

group :development do
  gem 'kicker'
  gem 'colored' # for examples
end

group :spec do
  gem 'bacon'
  gem 'json'
  gem 'mocha-on-bacon'
  gem 'prettybacon'

  if RUBY_VERSION >= '1.9.3'
    gem 'rubocop'
    gem 'codeclimate-test-reporter', :require => nil
    gem 'simplecov'
  end
end
