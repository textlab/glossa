source "http://rubygems.org"

# Declare your gem's dependencies in rglossa.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# jquery-rails is used by the dummy application
gem "jquery-rails"

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'

gem "mysql2"
gem "devise", "~> 2.2.3"

gem "ember-source", github: "emberjs/ember.js"

group :development do
  # Use thin instead of WEBrick in development
  gem 'thin'

  gem 'pry'
  gem 'pry-doc'

  gem 'bullet'
end
