# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Rglossa
  class ApplicationController < ActionController::Base

    protect_from_forgery # See ActionController::RequestForgeryProtection for details

    ########
    private
    ########

    def received_id_for?(klass)
      params["#{klass}_id"].to_i > 0
    end

  end
end