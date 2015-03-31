module Rglossa
  class MediaFile < ActiveRecord::Base
    self.table_name = "rglossa_media_files"
    attr_accessible :line_key_begin, :line_key_end, :basename

    belongs_to :corpus

  end
end
