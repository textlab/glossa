# permissions.rb
# Copyright 2011 The Text Laboratory, University of Oslo
# Author: Anders Nøklestad

# Include this module into controllers that need access control.
# When the module is included into a controller, its default behaviour
# is to deny everybody access to all actions in the controller and all
# controllers that inherit from it.
#
# Thus, if you include the module in your ApplicationController, all
# actions in all of the controllers in your application will be protected.
# From there on you can specify which roles have access to particular
# actions in your controllers using the +allow_for+ decorator-like method
# call (see below).
#
# You can also call "default_permissions :allow" in particular controllers
# to specify that all actions of the controller should be accessible
# to everyone by default, and then use the +allow_for+ and +deny_for+
# decorator-like methods to protect selected actions when needed. This makes
# sense, for instance, if you have an intranet application which should
# mostly only be accessible for logged-in users, but there are one or more
# areas of the app that should be open to anonymous users. These areas can
# then be handled by controllers where "default_permissions :allow" has been
# specified (but certain actions can still be protected by +allow_for+ or
# +deny_for+ calls).
#
# A call to +allow_for+ only grants access to the listed roles, regardless
# of whether the default permission of the controller is :allow or :deny.
# On the other hand, +deny_for+ is only useful if the default permission is
# :allow; it has no effect if the default permission is :deny. (The alternative
# interpretation, that a call to +deny_for+ would grant access to all roles
# not listed even if the default permission is :deny, is considered too insecure,
# since it would automatically grant access to any new roles created in the
# system. If you want to deny access to anonymous users and allow
# everyone else, use "allow_for :logged-in" instead.)
#
# Finally, if your application is mostly open to anyone, but has certain areas
# that should only be accessible for users with certain roles, you can override
# the "factory setting" by calling "default_permissions :allow" in your
# ApplicationController and then calling "default_permissions :deny" in those
# controllers that handle the protected areas.
#
# As mentioned above, each action method definition in a controller can be
# preceded by a call to +allow_for+ or +deny_for+ to specify which roles can
# or cannot access this action. Each of these methods takes a single argument,
# which can either be the name of a single role or an array of roles. Role names
# should be specified as symbols. The special symbol :all can be used to specify
# that everybody should be allowed access to the action. Furthermore, the symbols
# :logged_in and :anonymous can be used to refer to logged-in and non-logged-in
# users, respectively.
#
# Example:
#
# class ApplicationController < ActionController::Base
#
#   default_permission :allow   # overrides the "factory setting" of :deny
#
# end
#
#
# class DiscussionsController < ApplicationController
#
#   def view_post         # accessible to anyone because of inheritance of
#     ....                # ApplicationController's default permission
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
#   allow_for [:admin, :superadmin]   # only accessible to admins
#   def delete_topic
#     ....
#   end
#
# end
#
#
# class AdminController < ApplicationController
#
#   default_permission :deny  # overrides the default setting found in the ApplicationController
#
#   allow_for :all            # this particular action is accessible to anyone
#   def show_public_info
#     ....
#   end
#
#   allow_for [:admin, :superadmin]   # only accessible to admins
#   def create_new_document
#     ....
#   end
#
#   def useless   # not accessible to anyone - needs an allow_for specification!
#     ....
#   end
#
# end
#

module Permissions
  def self.included(base)
    base.extend ClassMethods

    base.send(:before_filter, :check_action_permissions)
  end

  def check_action_permissions
    puts current_user
  end

  module ClassMethods
    def default_permission(permission)
      @default_permission = permission
    end

    def allow_for(roles)
      @latest_allowed = roles
    end

    def deny_for(roles)
      @latest_denied = roles
    end

    def method_added(method_name)
      @allowed_roles ||= {}
      @allowed_roles[method_name] = @latest_allowed if @latest_allowed
      @latest_allowed = nil

      @denied_roles ||= {}
      @denied_roles[method_name] = @latest_denied if @latest_denied
      @latest_denied = nil
    end
  end
end
