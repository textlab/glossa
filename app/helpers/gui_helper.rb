module GuiHelper
  def possibly_debug_suffix
    Rails.env == 'development' ? '-debug' : ''
  end
end
