require 'i18n-js'

Rails.application.config.assets.paths <<
  SimplesIdeias::I18n::Engine.root.join('vendor', 'assets', 'javascripts').to_s


module Rglossa
  @taggers = {}

  Dir.glob(Rglossa::Engine.root.join('config', 'taggers', '*')) do |filename|
    tagger = File.basename(filename, '.json')
    @taggers[tagger] = JSON.parse(File.read(filename))
  end

  def self.taggers
    @taggers
  end
end
