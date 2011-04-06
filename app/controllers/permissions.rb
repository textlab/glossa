# permissions.rb
# Copyright 2011 The Text Laboratory, University of Oslo
# Author: Anders Nøklestad

# Include this module into controllers that need access control.
# Prepend each action with a call to allow_for or deny_for to specify
# which roles can or cannot access this action. The special symbol
# :all can be used to specify that everybody should be allowed access.
#
# For example:
#
#   allow_for :all
#   def index
#     ....
#   end
#
#   allow_for [:admin, :superadmin]; deny_for :member
#   def create_new_document
#     ....
#   end
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
