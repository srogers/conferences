require_relative 'boot'

require 'rails/all'  # TODO - could exclude ActionCable and TestUnit here

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Conferences
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    #rails_admin demands this configurations to launch successfully on Heroku
    config.assets.enabled = true

    config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec, :fixture => true, :views => true, :webrat => true
      g.fixture_replacement :factory_bot, :dir => "spec/factories"
      g.form_builder :simple_form
    end

    # Params that will be skipped for logging and error reporting
    config.filter_parameters << :password
  end
end
