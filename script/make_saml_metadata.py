#!/usr/bin/env python2
# encoding: utf-8

# Script for generating metadata that need to be sent to an identity provider (IdP), such as Feide
# Change APP_URL and CONFIG appropriately

import sys
import re
import saml2.config
import saml2.metadata
import saml2.validate
from saml2 import BINDING_HTTP_REDIRECT
from saml2 import BINDING_HTTP_POST
from saml2.saml import NAME_FORMAT_URI

if len(sys.argv) != 2:
  print "Usage: ./make_saml_metadata.py idp_name"
  sys.exit(1)
idp = re.sub(r'[^a-zA-Z_]', '', sys.argv[1]).lower()

APP_URL = "https://www.tekstlab.uio.no/glossa2"
CONFIG = {
    "entityid": "%s/saml/metadata/%s" % (APP_URL, idp),
    "description": "The Glossa corpus search system",
    "service": {
        "sp": {
            "name": "Glossa at University of Oslo",
            "endpoints": {
                "assertion_consumer_service": [("%s/auth/%s" % (APP_URL, idp), BINDING_HTTP_POST)],
                "single_logout_service" : [("%s/logout/%s" % (APP_URL, idp), BINDING_HTTP_REDIRECT)],
            },
            "required_attributes": ["edupersonprincipalname", "mail"],
            "optional_attributes": ["displayname"],
            },
    },
    # Key and cert file used by the Apache instance that serves Glossa:
    "key_file": "/etc/pki/tls/private/www.tekstlab.uio.no.key",
    "cert_file": "/etc/pki/tls/certs/www.tekstlab.uio.no.crt",
    "organization": {
        "name": "Text Laboratory, University of Oslo",
        "display_name": [("Text Laboratory, University of Oslo","en")],
        "url": "https://www.hf.uio.no/iln/om/organisasjon/tekstlab/",
    },
    "contact_person": [{
        "given_name": "Anders",
        "sur_name": "Nøklestad",
        "email_address": ["anders.noklestad@iln.uio.no"],
        "contact_type": "technical",
        },
    ],
    "name_form": NAME_FORMAT_URI
}

cnf = saml2.config.Config().load(CONFIG, metadata_construction=True)
eid = saml2.metadata.entity_descriptor(cnf)
saml2.validate.valid_instance(eid)
print saml2.metadata.metadata_tostring_fix(eid, {"xs": "http://www.w3.org/2001/XMLSchema"}, None)
