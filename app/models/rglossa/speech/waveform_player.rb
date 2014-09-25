module Rglossa
module Speech

class WaveformPlayer
  def self.conf_path
    Rails.root.join('config/waveforms.json').to_s
  end

  def self.conf
    JSON.parse(File.read(self.conf_path))
  end
end

end
end
