require 'i18n-js'

Rails.application.config.assets.paths <<
  SimplesIdeias::I18n::Engine.root.join('vendor', 'assets', 'javascripts').to_s
