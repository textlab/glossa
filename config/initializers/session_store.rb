# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rglossa_session',
  :secret      => 'b5752b4fabf77c9ec894279bba3080258d8fb6698e6a62a3a878598a553bcce59b600ce9599d32ed45391bbb969d4e6fda1a49faeed26902d4bc546023a67e6c'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
