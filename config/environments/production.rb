Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Heroku/StackOverflow says not to set this to true in production - used to be necessary, but not anymore.
  # It must be explicitly set to false. The name is deceptive: pre-compile still happens, but not compile per request.
  # https://devcenter.heroku.com/articles/rails-asset-pipeline#compile-set-to-true-in-production
  # This must be paired with "config.public_file_server.enabled = true" or no assets will be served at all.
  config.assets.compile = false

  # This comes from https://devcenter.heroku.com/articles/getting-started-with-rails5
  # Has to be true when assets.compile = false
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Action Cable endpoint configuration
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Don't mount Action Cable in the main server process.
  # config.action_cable.mount_path = nil


  # SSL now works on Heroku for both fee and paid apps, so force SSL in both staging and production.
  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true
  config.ssl_options = {  redirect: { status: 307, port: 81 } }

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "conferences_#{Rails.env}"
  # config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  config.action_mailer.default_url_options = { host: ENV['MAIL_HOST'] }

  # This is necessary because several models use URL helpers to generate URLs for CSV output
  Rails.application.routes.default_url_options[:host] = ENV['MAIL_HOST']

  ActionMailer::Base.smtp_settings = {
    :port           => ENV['MAILGUN_SMTP_PORT'],
    :address        => ENV['MAILGUN_SMTP_SERVER'],
    :user_name      => ENV['MAILGUN_SMTP_LOGIN'],
    :password       => ENV['MAILGUN_SMTP_PASSWORD'],
    :domain         => ENV['MAIL_HOST'],
    :authentication => :plain,
    :enable_starttls_auto => true    # SendGrid had this - carrying it forward
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true
  # config.i18n.fallbacks = [I18n.default_locale] This might be necessary with  I18n (>= 1.1.0) and Rails (< 5.2.2)

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :silence

  config.log_level = :info

  # Suppress ActionView logging of render times:
  ActiveSupport::on_load :action_view do
    %w{render_template render_partial render_collection}.each do |event|
      ActiveSupport::Notifications.unsubscribe "#{event}.action_view"
    end
  end

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
