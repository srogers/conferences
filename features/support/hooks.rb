require "authlogic/test_case"


Before('not @not_logged_in') do |scenario|
  # Handle login before every scenario except those with the tag above - for the few pre-login scenarios
  # Mention the role in the scenario title to be logged in as that role/user.
  email = case scenario.name
    # Role options
    when /admin/i           then 'admin@example.com'
    when /editor/i          then 'editor@example.com'
    when /reader/i          then 'reader@example.com'
  end

  Rails.logger.debug "\n\nStarting scenario: #{scenario.name} with login as #{email}"

  # for Scenarios tagged with @javascript truncation is required for DB Cleaner because the browser and
  # Cucumber are not in the same thread and don't share the same transaction - Cucumber can't roll it back.
  # However, by weirdness or design, it seems to be doing deletion after each JS scenario. So here,
  # we check to see if the DB is gone - if so, reload it. There's no way around the slow deleting and
  # reloading - the only thing that's not clear is why database_cleaner doesn't automagically reload the data.

  unless User.where(:email => email).first
    # Seed the DB with everything from the fixtures directory - just like at startup in support/env.rb
    ActiveRecord::FixtureSet.reset_cache
    fixtures_folder = File.join(Rails.root, 'spec', 'fixtures')
    fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
    ActiveRecord::FixtureSet.create_fixtures(fixtures_folder, fixtures)
  end

  @current_user = User.where(:email => email).first
  # in the normal login case, we consider the user to be current on policies
  @current_user.privacy_policy_current!

  visit login_path
  fill_in("user_session_email",    :with => email)
  fill_in("user_session_password", :with => 'tester1')
  click_button("Log in")

  # Check right here whether login worked - if not, check out fixtures
  page.body.should_not =~ /Unable to log in/m
  page.body.should_not =~ /User name or password are incorrect/m
  page.body.should     =~ /Objectivist Media/m     # This is in the landing page
end

Before('@not_logged_in') do |scenario|
  # when running everything at once, the @javascript tagged scenarios will leave the DB wiped for the next feature

  Rails.logger.debug "\n\nStarting scenario: #{scenario.name} without login"

  unless User.where(:email => 'aaron@example.com').first
    # Seed the DB with everything from the fixtures directory - just like at startup in support/env.rb
    ActiveRecord::FixtureSet.reset_cache
    fixtures_folder = File.join(Rails.root, 'spec', 'fixtures')
    fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
    ActiveRecord::FixtureSet.create_fixtures(fixtures_folder, fixtures)
  end
end

#After('not @not_logged_in') do |scenario|
# apparently this isn't necessary
#visit logout_path
#end

After do |scenario|
  unless scenario.failed?
    raise Capybara::ExpectationNotMet if @step_failures_were_rescued
  end
end

# from http://bjeanes.com/2010/09/pausing-cucumber-scenarios-to-debug
AfterStep('@pause') do
  print "Press Return to continue"
  STDIN.getc
end
