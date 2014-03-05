Rails.application.config.assets.paths <<
    Rglossa::Speech::Engine.root.join('vendor', 'assets', 'flash').to_s
