# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require "cancan/matchers"
require 'webrat/core/matchers' # RSpec 2 doesn't include have_tag - get it from webrat matchers instead

# This does approximately the same thing as the venerable AuthenticatedSystem test helpers
require 'authlogic/test_case'
include Authlogic::TestCase
include RSpecHtmlMatchers

#include ActionDispatch::TestProcess  # gets fixture_file_upload helper

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.before(:each) do |e|
    # ::Rails.logger.info("\nRspec metadata:  #{ e.metadata }"
    full_example_description = "#{e.metadata[:full_description]}"
    ::Rails.logger.info("\n\n#{full_example_description}\n#{'-' * (full_example_description.length)}")
  end

  # Works around issues related to integrating "rails-controller-testing" gem that should be fixed in
  # Rails 5 final and Rspec 3.5.0 - until then, patch:
  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end
end

# Stub up all the role methods for a given role. This is necessary because cancan routinely
# hits all the roles in the spec of a controller that calls 'load_and_authorize_resource'.
def stub_role_methods(mock_user, roles)
  roles = [roles] unless roles.is_a?(Array)
  Role::ROLES.each do |role_token|
    role = role_token.to_s  # allow a symbol to be passed - e.g., pretend_to_be_authenticated(:role => :admin)
    allow(mock_user).to receive(role.downcase+"?").and_return roles.include?(role)
  end
  return mock_user
end

# sets up a mock user that handles the methods around being logged in, having role(s) and being authorized for certain
# resources.
def mock_auth_user(stubs={})
  role = stubs[:role].present? ? stubs[:role] : Role::ADMIN
  @mock_auth_user ||= double(User, {
      :name  => 'Testing Userperson',
      :email => 'tester@example.com',
      :time_zone => "Central Time (US & Canada)"
  }.merge(stubs.except(:role)))
  # sets up the role methods like admin? used by cancan
  stub_role_methods(@mock_auth_user, role)
end

# Set up the basic elements that controllers and views would expect to find when
# a user is logged in. This doesn't cover every single thing, but the most common
# things needed. Pass in seldom-used stubs for the user. To test alternate
# values in specs, either call again (we're not using ||= here as is commonly done with
# mock models) or simply stub an alternate value for the method being tested.
# It's called "pretend" as a reminder that this isn't real authentication - it's a faster
# and simpler shortcut that supports the most common things that happen in views and controllers.
#
# If you get a cryptic error like:
#   You must activate the Authlogic::Session::Base.controller with a controller object before creating objects
# it means you forgot to call this method before accessing current_user methods

def get_test_environment
  if defined? view
    return view          # we're in a view spec - 'template' is deprecated, now it's 'view'
  elsif defined? helper
    return helper        # we're in a helper spec
  else
    return controller    # we're in a controller spec
  end
end

# Mock up things like current_user that ApplicationController provides
# The user gets admin role by default. Pass in a role and let the helper stub in the role predicate methods.
def pretend_to_be_authenticated(user_stubs={})
  test_environment = get_test_environment

  # To get the current user defined - compute it in this context, where RSpec is defined
  @current_user = mock_auth_user(user_stubs)
  # Then set it in an instance variable in the controller/view/helper.
  test_environment.instance_variable_set :@current_user, @current_user
  # Then define a current_user method that hands back the thing we defined.
  test_environment.singleton_class.class_eval do
    def current_user
      return @current_user
    end
  end
  # Something different about Rails 5 or this project requires this additional stubbing in views.
  # Could be because the concepts/show views use the can? method, which is unusual.
  # Without this, current_user isn't seen anywhere - shouldn't be necessary to brute-force it in.
  if defined? view
    controller.singleton_class.class_eval do
      def current_user
        return @current_user
      end
    end
  end
end

# Mocks up a nil current_user, so the controller / view specs won't get undefined error for current_user
def pretend_to_be_logged_out
  test_environment = get_test_environment

  # To get the current user defined - compute it in this context, where RSpec is defined
  @current_user = nil
  # Then set it in an instance variable in the controller/view/helper.
  test_environment.instance_variable_set :@current_user, @current_user
  # Then define a current_user method that hands back the thing we defined.
  test_environment.singleton_class.class_eval do
    def current_user
      return @current_user
    end
  end

  # Something different about Rails 5 or this project requires this additional stubbing in views.
  # Could be because the concepts/show views use the can? method, which is unusual.
  # We pass in a mock without any methods defined, which patches the CanCan problem hopefully without masking any genuine errors
  # Without this, current_user isn't seen anywhere - shouldn't be necessary to brute-force it in.
  if defined? view
    controller.singleton_class.class_eval do
      def current_user
        return @current_user
      end
    end
  end
end

# In contrast to pretend_to_be_authenticated, this method logs in an actual user, which can be from a fixture or a factory.
# The controller spec needs to say "setup :activate_authlogic" and then call log_in with a user. Several conditions are
# checked along the way, because if anything goes wrong, it should fail, not continue silently without being authorized.
# NOTE: if :activate_authlogic is called within an describe/context block, and log_in is called outside the scope of
#       where authlogic has been activated, the login will silently fail.
def log_in(user)
  log_out if @session
  expect(user).not_to be_nil
  @session = UserSession.create!(user, false)
  expect(@session).to be_valid
  result = @session.save
  expect(result).to be_truthy
  @current_user = user

  # Something different about Rails 5 or this project requires this additional stubbing in views.
  # Could be because the concepts/show views use the can? method, which is unusual?
  # Without this, current_user isn't seen anywhere - shouldn't be necessary to brute-force it in.
  if defined? view
    view.singleton_class.class_eval do
      def current_user
        return @current_user
      end
    end

    controller.singleton_class.class_eval do
      def current_user
        return @current_user
      end
    end
  end
end

def log_out
  @session.destroy if @session
  @session = nil
end
