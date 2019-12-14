source 'https://rubygems.org'

ruby '2.5.7'

gem 'rails', '5.2.3'
gem 'pg'
gem 'puma'
gem 'uglifier'
gem 'coffee-rails'
gem "haml-rails"                    # enables HAML in the asset pipeline
gem 'jquery-rails'                  # Bootstrap also requires this
gem 'jquery-ui-rails'               # Used for tag input fields

gem 'acts-as-taggable-on'
gem 'authlogic'                     # Bumped to version 5 which removes user-validation shortcuts
gem 'autoprefixer-rails'            # bootstrap needs this
gem 'bootstrap' , '~> 4.1'          # This is what actually gets bootstrap 4.x installed, and determines the current version
gem 'cancancan'
gem 'carrierwave'
gem "chartkick"                     # used for charts
gem 'cookies_eu'                    # Handles the pop-up and content
gem 'country_select'                # provides country selector that works with simple_form (country_state_select looks good, but isn't up to Rails 5, and requires Turbolinks)
gem 'fastimage'                     # for finding the size of reference images to calculate the height for layout
gem 'fast_jsonapi'                  # for serializing responses to JSON requests
gem 'fog-aws'                       # naming fog-aws specifically avoids a lot of extra gems
gem "font-awesome-sass", '~> 5.0'   # bundles font-awesome in a way that is compatible with Rails - 5.x goes with FontAwesome 5.x
gem 'friendly_id'                   # manages sluggified URLs
gem 'gon'                           # handles passing Ruby variables over to JavaScript
gem 'groupdate'                     # provides easy group_by_year for presentations charts
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
gem 'scout_apm'                     # replacement for New Relic
gem 'select2-rails'                 # used for autocomplete select boxes
gem 'sentry-raven'
gem 'sidekiq'
gem 'sidekiq-status'
gem 'simple_form'
gem 'social-share-button'
gem 'trix', git: 'https://github.com/bcoia/trix.git', tag: 'v0.11.2'    # rich text editing for presentation descriptions - fork fixes a bug in Rails 5.2 that breaks input
#gem 'turbolinks', '~> 5.x'         # removed because the caching breaks select2

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  gem 'byebug', platform: :mri      # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'dotenv-rails'
  gem "factory_bot_rails"           # consider setting up factories as tests get more robust
  gem "pry"                         # debug console support for development and cucumber
  # gem "foreman"                     # runs the server specified by Procfile - a Heroku-compatible way of running the server
  # gem "thin"                        # for the times when Puma is unstable
end

group :development do
  gem "better_errors"               # adds some nice error handling in development - MUST NOT escape from the development block - Requires Ruby 2.0.0 now
  gem "binding_of_caller"           # adds variable inspection command line to better_errors
  gem "brakeman"
  gem 'bullet'                      # looks for N+1 queries and unnecessary eager loading
  gem 'letter_opener_web'
  gem 'listen'
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
