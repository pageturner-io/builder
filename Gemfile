source 'https://rubygems.org'

# Prevent invalid byte sequence in US-ASCII (Encoding::InvalidByteSequenceError)
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

gem 'sinatra'
# sinatra-contrib messes with the global namespace,
# require: false lets Rake tasks run properly
gem 'sinatra-contrib', require: false
gem 'sinatra-initializers'

# common gems
gem 'json'
gem 'activesupport'
gem 'i18n'
gem 'dotenv'

# API utils
gem 'rack-parser'
gem 'rack-cors'

# App specifics
gem 'git'
gem 'sidekiq'

group :development, :test do
  gem 'guard'
  gem 'guard-rspec'
  gem 'pry-byebug'
end

group :test do
  gem 'rack-test'
  gem 'rspec'
  gem 'json_spec'

  # code coverage
  gem 'simplecov',                 require: false
  gem 'codeclimate-test-reporter', require: false
end
