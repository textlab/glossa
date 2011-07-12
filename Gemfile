source 'http://rubygems.org'

gem 'rails', '3.0.7'
# NOTE! We can use the latest version of mysql2 when Rails 3.1 is released
gem 'mysql2', "~> 0.2.6"

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3-ruby', require: 'sqlite3'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'
gem 'authlogic', git: 'https://github.com/threefunkymonkeys/authlogic.git'

# Squeel Query DSL
gem "squeel"

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

group :development do
  # Use mongrel instead of WEBrick in development
  gem "mongrel", ">= 1.2.0.pre2"
end

group :test do
  gem 'rspec'
  gem 'rspec-rails'
end
