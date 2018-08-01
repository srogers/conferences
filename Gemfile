source 'https://rubygems.org'

ruby '2.4.4'

gem 'rails', '5.2.0'
gem 'pg'
gem 'puma'
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
gem "haml-rails"                    # enables HAML in the asset pipeline
gem 'jquery-rails'                  # Bootstrap also requires this

gem 'acts-as-taggable-on'
gem 'authlogic'                     # As of version 3.5, authlogic is now compatible with Rails 5
gem 'autoprefixer-rails'            # bootstrap needs this
gem 'bootstrap' , '~> 4.1'          # This is what actually gets bootstrap 4.x installed, and determines the current version
gem 'cancancan'
gem 'carrierwave'
gem 'country_select'                # provides country selector that works with simple_form (country_state_select looks good, but isn't up to Rails 5, and requires Turbolinks)
gem 'fog-aws'                       # naming fog-aws specifically avoids a lot of extra gems
gem "font-awesome-sass", '~> 5.0'   # bundles font-awesome in a way that is compatible with Rails - 5.x goes with FontAwesome 5.x
gem 'friendly_id'                   # manages sluggified URLs
gem 'jbuilder', '~> 2.0'
gem 'kaminari'                      # a more modern pagination replacement for Will Paginate
gem 'link_thumbnailer'
gem 'prawn'                         # for generating the PDF export
gem 'prawn-icon'                    # provides a simple interface to FontAwesome and other icons to match online styles
gem 'prawn-styled-text'             # supports minimal HTML in PDF generation for handling rich text fields
gem 'prawn-table'                   # supports table layout for formatted details
gem 'rails-assets-tether'           # enables tooltips properly in the pipeline with bootstrap-sass
gem 'rmagick'
gem 'rubyzip'                       # Used for zipping PDF for download
gem 'select2-rails'                 # used for autocomplete select boxes
gem 'sidekiq'
gem 'sidekiq-status'
gem 'simple_form'
gem 'social-share-button'
gem 'trix', git: 'https://github.com/bcoia/trix.git'    # rich text editing for presentation descriptions - fork fixes a bug in Rails 5.2 that breaks input
#gem 'turbolinks', '~> 5.x'         # removed because the caching breaks select2

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem "factory_bot_rails"           # consider setting up factories as tests get more robust
  gem "foreman"                     # runs the server specified by Procfile - a Heroku-compatible way of running the server
  gem "pry"                         # debug console support for development and cucumber
  gem "thin"                        # for the times when Puma is unstable
end

group :development do
  gem "better_errors"               # adds some nice error handling in development - MUST NOT escape from the development block - Requires Ruby 2.0.0 now
  gem "binding_of_caller"           # adds variable inspection command line to better_errors
  gem 'letter_opener_web'
  gem 'listen', '~> 3.0.5'
end

group :test do
  gem 'cucumber-rails', :require => false  # gets Gherkin, Cucumber, Capybara on its own
  gem 'database_cleaner'            # database_cleaner is not required, but highly recommended
  gem 'rspec-collection_matchers'   # adds back some matchers like :errors_on to Rspec 3
  gem 'rspec-html-matchers'         # brings back have_tag matchers
  gem "rspec-rails"                 # doesn't seem to be necessary to name "rspec" separately
  gem 'rails-controller-testing'    # brings in the "assigns" method
  gem 'selenium-webdriver'          # as of Capybara 2.1 this has to be explicitly added
  gem 'webrat'                      # specs use this for the tag matchers
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
