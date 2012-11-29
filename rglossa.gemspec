$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rglossa/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rglossa"
  s.version     = Rglossa::VERSION
  s.authors     = ["Anders Nøklestad, André Lynum"]
  s.email       = ["tekstlab-post@iln.uio.no"]
  s.homepage    = "http://www.hf.uio.no/iln/english/about/organization/text-laboratory/"
  s.summary     = "The Glossa corpus search system"
  s.description = "Ruby on Rails version of the Glossa system for corpus search and results management"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'rails', '~> 3.2.9'
  s.add_dependency "jquery-rails"
  s.add_dependency 'oj'  # more efficient parsing and generation of JSON
  s.add_dependency 'turbo-sprockets-rails3'  # faster precompilation of assets
  s.add_dependency 'active_model_serializers'
  s.add_dependency 'devise'
  s.add_dependency 'ember-rails'
  s.add_dependency 'globalize3'
  s.add_dependency 'hirb'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rb-fsevent', '~> 0.9.1'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'konacha'  # for testing JavaScript with Mocha and chai
end
