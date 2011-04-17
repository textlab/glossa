# permissions.rb
# Copyright 2011 The Text Laboratory, University of Oslo
# Author: Anders Nøklestad

# Include this module into controllers that need access control. The module
# provides the controller and its subclasses with four class methods:
# +default_allowed+, +allow_for+, +also_allow_for+, and +deny_for+. Each of
# these methods takes one or more role names as its argument(s). In addition
# to names of actual roles, the methods accept the following pseudo-role names:
# :all, :none, :logged_in, and :anonymous (i.e. not logged in).
#
# When the module is included into a controller, its default behaviour
# is to deny everybody access to all actions in the controller and all
# controllers that inherit from it. Thus, if you include the module in your
# ApplicationController, all actions in all of the controllers in your
# application will be protected. From there on you can use the +default_allowed+
# method at the top of a controller class definition to specify a set of roles that
# should have access to all the actions in the controller by default, and you can
# use the +allow_for+, +also_allow_for+, and +deny_for+ decorator-like methods to
# specify access to individual actions (see examples below).

# One common scenario is that you have an intranet application that should mostly
# only be accessible for logged-in users, but there may be one or more
# areas that should be open to anonymous users. You would then call
# "default_allowed :logged_in" in your ApplicationController and
# "default_allowed :anonymous" in those controllers that handle publicly
# available areas. +allow_for+, +also_allow_for+, and +deny_for+ may additionally
# be used to regulate access to individual actions in any of the controllers.
#
# Another common scenario is that you have a site which is mostly open to the public
# but contains certain areas that should only be accessible to logged-in users or
# even users with a special admin role. In this case, you can call
# "default_allowed :all" in your ApplicationController and use
# "default_allowed :logged_in", "default_allowed :admin", "allow_for :admin" etc.
# to protect certain controllers or individual actions in your controller subclasses.
#
# Note that a call to +allow_for+ restricts the set of allowed roles to the ones given,
# regardless of the default permissions of the controller. In other words, even if you
# have specified "default_allowed :all" at the top of your controller, a call to
# "allow_for :admin" will still deny access to the following action to anyone but
# admins. +also_allow_for+, on the other hand, adds the given set of roles to the
# ones defined by +default_allowed+ (in the controller or one of its ancestors).
#
# +deny_for+ is only useful if the list of roles given is more restrictive than the
# default set of allowed roles for the controller. Thus, if you have specified
# "default_allowed :admin" for your controller, a call to "deny_for :member" does
# not have any effect, since the +member+ role was not part of the default set of
# allowed roles anyway. In other words, a call to +deny_for+ does not automatically
# grant access to all roles that are not listed in the +deny_for+ call!
#
# As an example, let us look at some of the controllers you might define as part of
# a forum application:
#
# # We have a site that is mostly open to anyone without having to log in, so set
# # the default access to :all in the ApplicationController.
# class ApplicationController < ActionController::Base
#
#   default_allowed :all   # overrides the "factory setting" of :none
#
# end
#
#
# # Most discussion-related actions should be accessible to anyone without having
# # to log in, so inherit the default permissions from ApplicationController, but
# # restrict some of the actions.
# class DiscussionsController < ApplicationController
#
#   def view_post         # accessible to anyone because of inheritance of
#     ....                # ApplicationController's default permissions
#   end
#
#   allow_for :logged_in  # only accessible to logged-in users
#   def create_post
#     ....
#   end
#
#   deny_for :anonymous   # the same as "allow_for :logged_in"
#   def create_comment
#     ....
#   end
#
#   allow_for :admin, :superadmin        # only accessible to admins
#   def delete_topic
#     ....
#   end
#
# end
#
#
# # This controller handles administrative tasks, which should by default only
# # be accessible to admins and superadmins - some even only to superadmins. However,
# # even this controller may contain actions that should be accessible to additional
# # roles or even anonymous users.
# class AdminController < ApplicationController
#
#   default_allowed :admin, :superadmin  # overrides the default permissions that were
#                                        # set in the ApplicationController
#
#   allow_for :all            # this particular action is accessible to anyone
#   def show_public_info
#     ....
#   end
#
#   allow_for :superadmin     # only accessible to superadmins, not to ordinary admins
#   def create_new_forum
#     ....
#   end
#
#   also_allow_for :member    # accessible to members as well as admins and superadmins
#   def edit_preferences
#     ....
#   end
#
# end
#

module Permissions

  # Some useful role sets
  NOBODY = [:none].to_set
  EVERYBODY = [:anonymous, :all].to_set

  def self.included(base)
    base.class_eval do
      # +def_allowed+ needs to be inherited from the superclass unless it
      # is specifically set for a particular controller using a call to
      # +default_allowed+. Class variables won't work, since their values
      # are shared by the entire class hierarchy, but Rails' convenient
      # +class_attribute+ method is perfect for this.
      class_attribute :def_allowed
      self.def_allowed = NOBODY    # defaults to being maximally restrictive
    end
    base.extend ClassMethods

    # Register the filter that will do the actual access control checking
    base.send(:before_filter, :check_action_permissions)
  end

  def check_action_permissions
    roles = self.class.roles_for(params[:action])

    if current_user.nil?
      # User is not logged in and hence has no actual role. Allow if :all or :anonymous
      # are mentioned in the set of allowed roles and not in the set of denied roles.
      allowed = !(roles[:allowed] & EVERYBODY).empty? && (roles[:denied] & EVERYBODY).empty?
    else
      # User is logged in and hence has a role. Add :logged_in and :all to this role
      # and allow if at least one of these is mentioned in the set of allowed roles
      # and none of them in the set of denied roles.
      user_roles = [current_user.role.name.to_sym, :logged_in, :all].to_set
      allowed = !(roles[:allowed] & user_roles).empty? && (roles[:denied] & user_roles).empty?
    end

    raise AccessDenied unless allowed

  end

  module ClassMethods
    # Sets the set of roles that can access all actions in this controller and
    # its subclasses unless overridden by an +allow_for+ or +deny_for+ call or
    # extended by an +also_allowed_for+ call for individual actions.
    def default_allowed(*roles)
      self.def_allowed = set_with(roles)
    end

    # Sets the set of roles that can access the following action regardless of
    # the default setting for the controller.
    def allow_for(*roles)
      @latest_allowed = set_with(roles)   # will be used by the +method_added+ hook
    end

    # Extends the set of roles that can access the following action by adding the
    # given roles to the default set of allowed roles for the controller.
    def also_allow_for(*roles)
      @latest_also_allowed = set_with(roles)   # will be used by the +method_added+ hook
    end

    # Restricts the set of roles that can access the following action. The roles
    # listed here will be subtracted from the default set of allowed roles for
    # the controller.
    def deny_for(*roles)
      @latest_denied = set_with(roles)   # will be used by the +method_added+ hook
    end

    def method_added(method_name)
      # +@roles+ is specific to each individual controller and should
      # not be inherited. It is therefore suitably defined as an instance
      # variable on the class. Furthermore, it cannot be defined by
      # Permissions#included, since the module will only be included into the
      # base controller. Hence, we should define it here as needed.
      @roles ||= {}

      # Register the set of roles that are listed as being allowed to call this action,
      # based on the default set of allowed roles for the controller and the set of
      # roles given to any preceding call to +allow_for+ or +also_allow_for+.
      # Also register the set of denied roles given to +deny_for+ (if any). Both
      # of these will be used by the +check_action_permissions+ filter to determine
      # if the current user can access this action.
      @roles[method_name.to_sym] = {
          allowed: calculate_allowed_set,
          denied: @latest_denied || Set.new
      }

      # Make sure any roles set by +allow_for+, +also_allow_for+, or +deny_for+
      # are not carried over to the next action.
      @latest_allowed = @latest_also_allowed = @latest_denied = nil
    end

    def roles_for(action)
      @roles[action.to_sym] || { allowed: [:none].to_set, denied: Set.new }
    end

    ########
    private
    ########

    def set_with(roles)
      Array(roles).flatten.map(&:to_sym).to_set
    end

    def calculate_allowed_set
      @latest_allowed ||
          (@latest_also_allowed ? def_allowed + @latest_also_allowed : def_allowed)
    end
  end

  class AccessDenied < StandardError; end

end
