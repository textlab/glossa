module Rglossa
  class HomeController < ApplicationController
    layout 'application'

    def index
      if Rails.env == 'development' && params.has_key?(:user)
        session[:current_username] = params[:user]
      end
      unless params[:corpus].present?
        redirect_to front_url
      end
    end
  end
end
