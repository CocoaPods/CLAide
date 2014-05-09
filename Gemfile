source 'https://rubygems.org'

gem 'rake'

group :development do
  gem 'kicker'
end

group :spec do
  gem 'bacon'
  gem 'json'
  gem 'mocha-on-bacon'
  gem 'prettybacon'

  if RUBY_VERSION >= '1.9.3'
    gem 'rubocop'
    gem 'codeclimate-test-reporter', :require => nil

    # Bug: https://github.com/colszowka/simplecov/issues/281
    gem 'simplecov', '0.7.1'
  end
end
