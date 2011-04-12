# permissions.rb
# Copyright 2011 The Text Laboratory, University of Oslo
# Author: Anders Nøklestad

# Include this module into controllers that need access control. The module
# provides the controller and its subclasses with three class methods:
# +default_allowed+, +allow_for+, and +deny_for+. Each of these methods takes
# one or more role names as its argument(s). In addition to names of actual
# roles, the methods accept the following pseudo-role names: :all, :none,
# :logged_in, and :anonymous (i.e. not logged in).
#
# When the module is included into a controller, its default behaviour
# is to deny everybody access to all actions in the controller and all
# controllers that inherit from it. Thus, if you include the module in your
# ApplicationController, all actions in all of the controllers in your
# application will be protected. From there on you can use the +default_allowed+
# method at the top of a controller class definition to specify a set of roles that
# should have access to all the actions in the controller by default, and you can
# use the +allow_for+ and +deny_for+ decorator-like methods to specify
# access to individual actions (see examples below).

# One common scenario is that you have an intranet application that should mostly
# only be accessible for logged-in users, but there may be one or more
# areas that should be open to anonymous users. You would then call
# "default_allowed :logged_in" in your ApplicationController and
# "default_allowed :anonymous" in those controllers that handle publicly
# available areas. +allow_for+ and +deny_for+ may additionally be used to regulate
# access to individual actions in any of the controllers.
#
# Another common scenario is that you have a site which is mostly open to the public
# but contains certain areas that should only be accessible to logged-in users or
# even users with a special admin role. In this case, you can call
# "default_allowed :all" in your ApplicationController and use
# "default_allowed :logged_in", "default_allowed :admin", "allow_for :admin" etc.
# to protect certain controllers or individual actions in your controller subclasses.
#
# Note that a call to +allow_for+ restricts access to the listed roles, regardless
# of the default permissions of the controller. In other words, even if you have
# specified "default_allowed :all" at the top of your controller, a call to
# "allow_for :admin" will still deny access to the following action to anyone but
# admins.
#
# On the other hand, +deny_for+ is only useful if the list of roles given is more
# restrictive than the default set of allowed roles for the controller. Thus, if
# you have specified "default_allowed :admin" for your controller, a call to
# "deny_for :member" does not have any effect, since the +member+ role was not part
# of the default set of allowed roles anyway. In other words, a call to +deny_for+
# does not automatically grant access to all roles that are not listed in the
# +deny_for+ call!
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
# # even this controller may contain actions that should be accessible to anyone.
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
# end
#

module Permissions
  def self.included(base)
    base.class_eval do
      # +default_perm+ needs to be inherited from the superclass unless it
      # is specifically set for a particular controller. Class variables won't
      # work, since their values are shared by the entire class hierarchy, but
      # Rails' convenient +class_attribute+ method is perfect for this.
      class_attribute :default_perm
      self.default_perm = :deny
    end
    base.extend ClassMethods
    base.send(:before_filter, :check_action_permissions)
  end

  module ClassMethods
    def default_permission(permission)
      self.default_perm = permission
    end

    def allow_for(*roles)
      @latest_allowed = Array(roles).flatten.map(&:to_sym)  # will be used by the +method_added+ hook
    end

    def deny_for(*roles)
      @latest_denied = Array(roles).flatten.map(&:to_sym)   # will be used by the +method_added+ hook
    end

    def method_added(method_name)
      # +allowed_roles+ and +denied_roles+ are specific to each individual
      # controller and should not be inherited. They are therefore suitably
      # defined as instance variables on the class. Furthermore, they cannot
      # be defined by Permissions#included, since the module will only be
      # included into the base controller. Hence, we should define them here
      # as needed.
      @allowed_roles ||= {}

      # Calculate the set of roles that are allowed to call this action, based
      # on default_perm and the set of roles given to the immediately preceding
      # call to +allow_for+ (if any).
      @allowed_roles[method_name] = allowed_set(@latest_allowed)

      # Make sure any roles set by +allow_for+ are not carried over to the next action.
      @latest_allowed = nil

      # Same procedure for denied roles.
      @denied_roles ||= {}
      @denied_roles[method_name] = denied_set(@latest_denied)
      @latest_denied = nil
    end

    ########
    private
    ########

    def allowed_set(allowed_for_method)
      if self.default_perm == :allow
        allowed_for_method ? allowed_for_method.to_set : Set.new([:all])
      end
    end

    def denied_set(denied_for_method)
    end
  end

  ########
  private
  ########

  def check_action_permissions
  end
end
