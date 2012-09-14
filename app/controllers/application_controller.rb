# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper_method :application_root
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  ########
  private
  ########

  # Returns the path on which the application is mounted (e.g., '/myapp' or simply '/')
  def application_root
    path = request.env['REQUEST_PATH']
    if path
      path.ends_with?('/') ? path[0..-2] : path[0..-1]
    else
      ''
    end
  end
end
