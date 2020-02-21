# This file defines steps that twiddle with the application and data, in contrast to web_steps
# that should be primarily about twiddling knobs on the interface. These are mostly "Given"s
# Handy Xpath tester:  http://www.online-toolz.com/tools/xpath-editor.php

Given /^I am logged in as (.*) with password (.*)$/ do |email, password|
  @current_user = User.where(:email => email).first
  # in the normal login case, we consider the user to be current on policies
  @current_user.privacy_policy_current!

  visit login_path
  fill_in "user_session_email", :with => email
  fill_in "user_session_password", :with => password
  click_button "Log in"
  page.body.should_not =~ /Email is not valid/m
  page.body.should_not =~ /Password is not valid/m
  page.body.should =~ /Objectivist Media/m     # This is in the landing page
end
