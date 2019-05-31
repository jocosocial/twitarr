require File.expand_path('boot', __dir__)

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
# require 'action_mailer/railtie'
require 'active_job/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

# this is here because intellij doesn't recognize fattr for some reason
# class Module
#   alias_method :attr, :fattr
# end

module Twitarr
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # set up CORS handling
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/api/*', headers: :any, methods: [:get, :post, :put, :delete, :options]
        resource '/photo/*', headers: :any, methods: [:get, :options]
      end
    end

    # Don't generate system test files.
    config.generators.system_tests = nil

    Draper::Railtie.initializers.delete_if do |initializer|
      initializer.name == 'draper.setup_active_model_serializers'
    end

    config.assets.precompile += ['respond.js']

    config.autoload_paths += Dir[Rails.root.join('app', 'contexts', '{**}')]

    config.action_dispatch.perform_deep_munge = false

    config.photo_store = 'photo_storage'
  end
end
