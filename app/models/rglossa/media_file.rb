module Rglossa
  class MediaFile < ActiveRecord::Base
    attr_accessible :line_key, :basename
  end
end
