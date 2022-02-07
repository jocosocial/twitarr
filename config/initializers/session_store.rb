# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Rails.application.config.session_store(
  :redis_store,
  servers: [ENV.fetch('REDIS_URL_SESSION', 'redis://localhost:6379/0/session')],
  key: '_twitarr_session',
  expire_after: 30.days,
  same_site: :strict,
  secure: Rails.application.config.secure_cookies
)
