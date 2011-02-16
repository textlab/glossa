# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :application_root
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Used by ExtJs to limit the scope in which database queries are performed
  def model_scope
    current_user.pht_company
  end

  # Returns the path on which the application is mounted (e.g., '/myapp' or simply '/')
  def application_root
    path = request.env['REQUEST_PATH']
    if path
      path.ends_with?('/') ? path[0..-2] : path[0..-1]
    else
      ''
    end
  end

  ########
  private
  ########

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def access_denied
    render :text => 'Access denied', :status => 401
  end
end
