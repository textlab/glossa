module GuiHelper
  def possibly_debug_suffix
    RAILS_ENV == 'development' ? '-debug' : ''
  end
end
