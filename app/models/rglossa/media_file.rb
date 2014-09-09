module Rglossa
  class MediaFile < ActiveRecord::Base
    attr_accessible :line_key_begin, :line_key_end, :basename

    belongs_to :corpus

  end
end
