source 'http://rubygems.org'

gem 'rails', '3.2.9'

# PostgreSQL gems
gem 'pg'
# gem 'pg_array_parser'
# gem 'postgres_ext'
# gem 'pg_power'

gem 'oj'  # more efficient parsing and generation of JSON
gem 'turbo-sprockets-rails3'  # faster precompiling of assets

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.5'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier',     '>= 1.2.7'
end

gem 'jquery-rails'

gem "active_model_serializers", :git => "git://github.com/rails-api/active_model_serializers.git"

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'
gem 'debugger'

gem 'devise'

# Squeel Query DSL
# gem 'squeel'

gem 'ember-rails'
gem 'globalize3'

# Kaminari gem for Rails pagination
# gem 'kaminari'

# page_wrapper gem for Ember/Rails pagination
# gem 'page_wrapper'

gem 'hirb'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  # gem 'webrat'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'guard-rspec'
  gem 'poltergeist'
  gem 'konacha'  # for testing JavaScript with Mocha and chai
end

group :development do
  # Use thin instead of WEBrick in development
  gem 'thin'

  gem 'pry'
  gem 'pry-doc'
end
