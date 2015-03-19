# Copyright (c) 2010-2015 OneLogin, LLC
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Adapted to Glossa by Michał Kosek

module Rglossa
class SamlController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:acs, :logout]

  def sso
    settings = Account.get_saml_settings(params[:idp])
    if settings.nil?
      render :inline => "No Settings found"
      return
    end

    saml_request = OneLogin::RubySaml::Authrequest.new
    redirect_to(saml_request.create(settings, :RelayState => request.referer))
  end

  def acs
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    response.settings = Account.get_saml_settings(params[:idp])

    if response.is_valid?
      session[:user_id] = response.name_id
      session[:attributes] = response.attributes
      session[:idp] = params[:idp]
      logger.info "Sucessfully logged"
      logger.info "NAMEID: #{response.name_id}"
      redirect_to params[:RelayState]
    else
      render :inline => "SAML Response invalid"
    end
  end

  def metadata
    settings = Account.get_saml_settings(params[:idp])
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(settings)
  end

  # Trigger SP and IdP initiated Logout requests
  def logout
    # If we're given a logout request, handle it in the IdP logout initiated method
    if params[:SAMLRequest]
      return idp_logout_request

    # We've been given a response back from the IdP
    elsif params[:SAMLResponse]
      return process_logout_response
    else
      return sp_logout_request
    end
  end

  # Create an SP initiated SLO
  def sp_logout_request
    # LogoutRequest accepts plain browser requests w/o paramters
    settings = Account.get_saml_settings(params[:idp])

    if settings.idp_slo_target_url.nil?
      logger.info "SLO IdP Endpoint not found in settings, executing then a normal logout'"
      reset_session
    else
      # Since we created a new SAML request, save the transaction_id
      # to compare it with the response we get back
      logout_request = OneLogin::RubySaml::Logoutrequest.new()
      session[:transaction_id] = logout_request.uuid
      logger.info "New SP SLO for User ID: '#{session[:user_id]}', Transaction ID: '#{session[:transaction_id]}'"

      if settings.name_identifier_value.nil?
        settings.name_identifier_value = session[:user_id]
      end

      redirect_to(logout_request.create(settings, :RelayState => request.referer))
    end
  end

  # After sending an SP initiated LogoutRequest to the IdP, we need to accept
  # the LogoutResponse, verify it, then actually delete our session.
  def process_logout_response
    settings = Account.get_saml_settings(params[:idp])

    if session.has_key? :transation_id
      logout_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], settings, :matches_request_id => session[:transation_id])
    else
      logout_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], settings)
    end

    logger.info "LogoutResponse is: #{logout_response.to_s}"

    # Validate the SAML Logout Response
    if not logout_response.validate
      logger.error "The SAML Logout Response is invalid"
    else
      # Actually log out this session
      if logout_response.success?
        logger.info "Delete session for '#{session[:user_id]}'"
        reset_session
      end
    end
    redirect_to params[:RelayState]
  end

  # Method to handle IdP initiated logouts
  def idp_logout_request
    settings = Account.get_saml_settings(params[:idp])
    logout_request = OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest])
    if !logout_request.is_valid?
      logger.error "IdP initiated LogoutRequest was not valid!"
      render :inline => logger.error
    end
    logger.info "IdP initiated Logout for #{logout_request.name_id}"

    # Actually log out this session
    reset_session

    # Generate a response to the IdP.  :transaction_id sets the InResponseTo
    # SAML message to create a reply to the IdP in the LogoutResponse.
    #action, content = logout_response = OneLogin::RubySaml::Logoutresponse.new(nil, settings).
    #  create(:transaction_id => logout_request.transaction_id)

    #case action
    #  when "GET"
    #    # for GET requests, do a redirect on the content
    #    redirect_to content
    #  when "POST"
    #    # for POST requests (form) render the content as HTML
    #    render :inline => content
    #end    logout_request_id = logout_request.id

    logout_response = OneLogin::RubySaml::SloLogoutresponse.new.create(settings, logout_request_id, nil, :RelayState => params[:RelayState])
    redirect_to logout_response
  end
end
end
