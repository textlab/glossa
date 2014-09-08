module Rglossa
  class MediaFile < ActiveRecord::Base
    attr_accessible :line_key, :basename

    belongs_to :corpus

  end
end
