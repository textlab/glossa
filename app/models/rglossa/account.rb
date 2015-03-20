module Rglossa
class Account < ActiveRecord::Base
  def self.get_saml_settings(idp)
    # To make things simpler with environment variable names, allow only
    # (case-insensitive) Latin characters and the underscore:
    idp_caps = idp.gsub(/[^a-z_]/i, '').upcase
    idp_lc = idp_caps.downcase
    settings = OneLogin::RubySaml::Settings.new
    app_url = URI::join(ENV['APP_HOST_URL'], ENV['RAILS_RELATIVE_URL_ROOT'] + "/")
    settings.assertion_consumer_service_url        = URI::join(app_url, "auth/#{idp_lc}").to_s
    settings.assertion_consumer_logout_service_url = URI::join(app_url, "logout/#{idp_lc}").to_s
    settings.issuer                 = URI::join(app_url, "saml/metadata/#{idp_lc}")
    settings.idp_entity_id          = ENV["#{idp_caps}_IDP_ENTITY_ID"]
    settings.idp_sso_target_url     = ENV["#{idp_caps}_IDP_SSO_TARGET_URL"]
    settings.idp_slo_target_url     = ENV["#{idp_caps}_IDP_SLO_TARGET_URL"]
    settings.idp_cert_fingerprint   = ENV["#{idp_caps}_IDP_CERT_FINGERPRINT"]
    settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    settings
  end
end
end
