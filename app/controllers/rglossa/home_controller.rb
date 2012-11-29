class Rglossa::HomeController < ApplicationController

  def index
    if Rails.env == 'development' && params.has_key?(:user)
      session[:current_username] = params[:user]
    end
  end

end
