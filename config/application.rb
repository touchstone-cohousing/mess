require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mess
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # config.autoload_paths += []

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.x.from_email = "MESS <mess@aacoho.org>"
    config.x.webmaster_emails = ["tomsmyth@gmail.com"]

    config.active_job.queue_adapter = :delayed_job

    config.middleware.use ExceptionNotification::Rack,
      email: {
        email_prefix: "[MESS ERROR] ",
        sender_address: Rails.configuration.x.from_email,
        exception_recipients: %w{tomsmyth@gmail.com}
      }

    Devise.setup do |config|
      config.omniauth :google_oauth2, Settings.oauth.google.client_id, Settings.oauth.google.client_secret
    end

    config.secret_key_base = Settings.secret_key_base

    if Settings.smtp
      config.action_mailer.smtp_settings = {
        address: Settings.smtp.address,
        port: Settings.smtp.port,
        domain: Settings.smtp.domain,
        authentication: Settings.smtp.authentication.try(:to_sym),
        user_name: Settings.smtp.user_name,
        password: Settings.smtp.password
      }
    end

    config.action_mailer.default_url_options = { host: Settings.url.host }
  end
end
