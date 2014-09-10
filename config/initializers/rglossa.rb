require 'i18n-js'

Rails.application.config.assets.paths <<
  SimplesIdeias::I18n::Engine.root.join('vendor', 'assets', 'javascripts').to_s


module Rglossa
  @taggers = {}

  [Rglossa::Engine.root, Rails.root].each do |root|
    Dir.glob(root.join('config', 'taggers', '*.json')) do |filename|
      tagger = File.basename(filename, '.json')
      @taggers[tagger] = JSON.parse(File.read(filename))
    end
    Dir.glob(root.join('config', 'taggers', '*.yml')) do |filename|
      tagger = File.basename(filename, '.yml')
      @taggers[tagger] = YAML.load_file(filename)
    end
  end

  def self.taggers
    @taggers
  end
end
