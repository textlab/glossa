#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'base64'

if ARGV.size < 2 || ARGV.size % 2 != 0
  abort <<EOF
Usage: #{$0} idp-name metadata-url [idp-name metadata-url ...]
e.g. #{$0} FEIDE_TEST https://idp-test.feide.no/simplesaml/saml2/idp/metadata.php
EOF
end

idps = ARGV.each_slice(2).map {|idp, url| [idp.gsub(/[^a-z_]/i, '').upcase, url] }.reverse
puts "export IDP_LIST='#{idps.map(&:first).join(?:)}'"
idps.each do |idp, url|
  http_redirect = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
  metadata = Nokogiri::XML(open(url).read)
  cert = metadata.xpath(%Q{//ds:X509Certificate}).first.content
  printf """\
export #{idp}_IDP_ENTITY_ID='%s'
export #{idp}_IDP_SSO_TARGET_URL='%s'
export #{idp}_IDP_SLO_TARGET_URL='%s'
export #{idp}_IDP_CERT_FINGERPRINT='%s'
""" % [
    metadata.xpath(%Q{//md:EntityDescriptor/@entityID}).first.value,
    metadata.xpath(%Q{//md:SingleSignOnService[@Binding="#{http_redirect}"]/@Location}).first.value,
    metadata.xpath(%Q{//md:SingleLogoutService[@Binding="#{http_redirect}"]/@Location}).first.value,
    OpenSSL::Digest::SHA1.new(Base64.decode64 cert).to_s.scan(/../).join(?:).upcase,
  ]
end
