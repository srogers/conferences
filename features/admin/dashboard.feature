# This is the "smoke test" feature for Cucumber that checks the basics of the support files as
# well as the feature itself - i.e. that the login step and other support steps are working.

Feature: Admin Dashbaord
  In order to do anything
  As an admin
  I need to be able to log in

  # Tag scenarios this way in order to do the login explicitly
  @not_logged_in
  Scenario: Login and see the landing page
    Given I am logged in as admin@example.com with password tester1
    Then I should see the text "Objectivist Conferences"

  # Make sure the support steps for getting logged in as admin works
  Scenario: When I mention admin in the scenario name
    Then I should see the text "Objectivist Conferences"

  # Otherwise before hooks log in as admin when the scenario title mentions admin
  Scenario: I can see my admin dashboard from here
      # Just do any ole thing to clarify that we're where we think we are and things basically work
    When I follow "Users"
    Then I should see the text "admin@example.com"
