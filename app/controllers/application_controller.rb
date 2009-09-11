# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation

  access_control do
    ###########################################################################################
    # Setup some default access rules. May be overridden or extended in descendant controllers
    ###########################################################################################

    # Everyone is allowed to view objects
    allow all, :to => [:show]

    # Admin can do anything
    #allow :admin
    allow all

    # Logged-in users can create objectss
    allow logged_in, :to => [:index, :new, :create]

  end

  rescue_from 'Acl9::AccessDenied', :with => :access_denied

  def current_user
    # In development mode, we provide the username in the query string in order not to require Cosign.
    # In other modes, we expect the username to be provided by Cosign in the REMOTE_USER environment variable
    unless @current_user || RAILS_ENV == 'development'
      if RAILS_ENV == 'development'
        if params.has_key?(:user)
          session[:current_username] = params[:user]
        end
        current_username = session[:current_username]
      else
        current_username = request.env['REMOTE_USER']
      end
      unless current_username.blank?
        @current_user = PhtUser.find_by_username(current_username)
      end
    end
    @current_user
  end

  # Used by ExtJs to limit the scope in which database queries are performed
  def model_scope
    current_user.pht_company
  end

  ########
  private
  ########

  def access_denied
    render :text => 'Access denied', :status => 401
  end
end
