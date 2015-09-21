source 'https://rubygems.org'

ruby '2.2.2', engine: 'jruby', engine_version: '9.0.1.0'
#ruby=jruby-9.0.1.0

gem 'rails', '3.2.19'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'activerecord-jdbc-adapter', platform: :jruby
gem 'sqlite3', :platform => :ruby
gem 'jdbc-sqlite3', :platform => :jruby
gem 'mysql2', :platform => :ruby
gem 'jdbc-mysql', platform: :jruby
gem 'react-rails'
gem 'therubyracer', :platform => :ruby
gem 'therubyrhino', :platform => :jruby


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.5'
  gem 'coffee-rails', '~> 3.2.2'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.2.7'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

gem "rglossa-fcs", :github => 'textlab/rglossa-fcs'
#gem "rglossa-r", :github => 'textlab/rglossa-r'
gem 'nokogiri', '= 1.6.1'
gem 'devise', '~> 2.2.3'
gem 'cancan'

gem 'oj', :platform => :ruby  # more efficient parsing and generation of JSON
gem 'json', :platform => :jruby
gem 'turbo-sprockets-rails3'  # faster precompilation of assets
gem 'globalize', '~> 3.0.0'
gem 'i18n-js'
gem 'fastimage'
gem 'headless'
gem 'daemon_controller'
gem 'rubyzip'
gem 'ruby-saml'
gem "rserve-client", "~> 0.3.1"
gem 'ting'

group :development do
  gem 'thin', :platform => :ruby
  gem 'mizuno', :platform => :jruby
  gem 'pry'
  gem 'table_print'
  gem 'awesome_print'
  gem 'test-unit'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'guard-rspec'
  gem 'poltergeist'
  gem 'konacha'  # for testing JavaScript with Mocha and chai
end
