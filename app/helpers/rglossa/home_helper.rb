module Rglossa
  module HomeHelper
    def possibly_debug_suffix
      Rails.env == 'development' ? '-debug' : ''
    end
  end
end
