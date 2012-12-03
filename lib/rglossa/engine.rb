require 'ember-rails'

module Rglossa
  class Engine < ::Rails::Engine
    isolate_namespace Rglossa

    config.ember.variant = Rails.env

    # Override the standard template location set by ember-rails
    config.handlebars.templates_root = "rglossa/templates"
  end
end
