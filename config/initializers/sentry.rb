Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']

  # -- Old deprecated config
  # config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

  # -- New config for new features in sentry-ruby
  # To activate performance monitoring, set one of these options.
  # We recommend adjusting the value in production:
  config.traces_sample_rate = 1
  # or
  # config.traces_sampler = lambda do |context|
  #   true
  # end
end
