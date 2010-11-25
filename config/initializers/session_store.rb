# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_hyperde_mauricio_session',
  :secret      => '4bb0773e14af34dc34d69ffb0808c2ebe3020379986b01ee227e67b8fcd0f67cc28dd6e73b7bb3f5c935f7c1aaf8effeb7ac75cea23cee4db2feadb0404ee97e'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
