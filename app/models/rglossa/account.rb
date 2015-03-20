module Rglossa
class Account < ActiveRecord::Base
  def self.get_saml_settings(idp)
    # To make things simpler with environment variable names, allow only
    # (case-insensitive) Latin characters and the underscore:
    idp_caps = idp.gsub(/[^a-z_]/i, '').upcase
    settings = OneLogin::RubySaml::Settings.new
    app_host_url = ENV['APP_HOST_URL']
    url_root = ENV['RAILS_RELATIVE_URL_ROOT']
    settings.assertion_consumer_service_url        = URI::join(app_host_url, url_root,
                                                               "#{idp_caps.downcase}_auth").to_s
    settings.assertion_consumer_logout_service_url = URI::join(app_host_url, url_root,
                                                               "logout_#{idp_caps.downcase}_user").to_s
    settings.issuer                 = ENV["#{idp_caps}_ISSUER"]
    settings.idp_entity_id          = ENV["#{idp_caps}_IDP_ENTITY_ID"]
    settings.idp_sso_target_url     = ENV["#{idp_caps}_IDP_SSO_TARGET_URL"]
    settings.idp_slo_target_url     = ENV["#{idp_caps}_IDP_SLO_TARGET_URL"]
    settings.idp_cert_fingerprint   = ENV["#{idp_caps}_IDP_CERT_FINGERPRINT"]
    settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    settings
  end
end
end
