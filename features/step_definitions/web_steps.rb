# This file is no longer generated by Cucumber install. See the explanation at:
# https://github.com/cucumber/cucumber-rails/blob/f027440965b96b780e84e50dd47203a2838e8d7d/History.md
# and links to further reading about feature styles. So the general idea here is
# rather than replicating the original web_steps content, to pull them where needed
# while focusing on a more modern declarative style.

# This is a handy reference: https://github.com/normalocity/cucumber-web-steps/blob/master/web_steps.rb
# Also: Capybara cheat sheet https://gist.github.com/zhengjia/428105

# Put this into a scenario (before the error step) to get a print of the response body
Then /^I dumped the response$/ do
  puts body
  # capybara users puts body
end

Then /^I should( not)? see the text "(.*?)"$/ do |negate, text|
  if negate.blank?
    page.should have_content(text)
  else
    page.should_not have_content(text)
  end
end

Then /^I should( not)? see the "([^"]*)" button$/ do |negate, name|
  if negate.blank?
    find_button(name).should_not be_nil
  else
    has_button?(name).should_not be true
  end
end

# Just looks for the ID of the outer switch DIV - the "switch" class is not present in Cucumber because it breaks testing.
# It may be necessary to tweak this when Foundation is updated because they frequently twiddle with the implementation details
Then /^I should( not)? see the "([^"]*)" switch$/ do |negate, name|
  if negate.blank?
    page.should have_xpath("//div[@id='#{ name }']")
  else
    page.should_not have_xpath("//div[@id='#{ name }']")
  end
end

# This has to be the name of the visible checkbox that turns the switch on - not the hidden checkbox
# It may be necessary to tweak this when Foundation is updated because they frequently twiddle with the implementation details
When /^I turn (on|off) the "([^"]*)" switch$/ do |direction, name|
  if direction == 'on'
    page.check(name)
  else
    page.uncheck(name)
  end
end

# This is used to test the state of Foundation switches which are implemented as checkboxes.
# The switch may be used to change the value of a hidden field, etc. - this just checks the
# switch itself by looking at whether it is checked. Pass the ID, label, or name.
Then /^the "([^"]*)" switch should be (on|off)$/ do |switch_id, value|
  if value == 'on'
    page.has_checked_field?("#{switch_id}").should be true
  else
    # Make sure the switch is present AND unchecked
    page.should have_xpath("//input[@id='#{ switch_id }']")
    page.has_checked_field?("#{switch_id}").should be false
  end
end

# Visit, be on, and go to page names
Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )visit (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )follow "([^\"]*)"$/ do |link|
  click_link(link)
end

# Check whether an input is disabled based on its label or ID
# For now, not existing at all is the same as being disabled.
# TODO - see if the handling of disabled changes in Capybara 2.1 https://github.com/jnicklas/capybara/pull/996
Then /^"([^\"]*)" should be enabled$/ do |label_or_id|
  field_labeled(label_or_id).native.enabled?.should == true
end

# This might sort-of work based on the idea that disabled elements can't be found
Then /^"([^\"]*)" should not be enabled$/ do |label_or_id|
  label_exists = all("label").detect { |l| l.has_content?(label_or_id) }
  if label_exists
    page.has_no_field?(label_or_id).should == true
    page.has_no_select?(label_or_id).should == true
  else
    raise "Label or ID #{label_or_id} doesn't seem to exist at all."
  end
end
# find(label_or_id, :disabled => true) doesn't work yet, but should soon

# Don't pass the "#" along with the object ID, when using ID as a selector
Then /^Checkbox "([^"]*)" should not be checked$/ do |checkbox_id_label_or_name|
  page.has_checked_field?("#{checkbox_id_label_or_name}").should be false
end

# Don't pass the "#" along with the object ID, when using ID as a selector
When /^I check "(.*?)"$/ do |checkbox_id_label_or_name|
  page.check(checkbox_id_label_or_name)
end

# This is used for choosing radio buttons (formerly Foundation switches, when they were buttons)
When /^I choose "(.*?)"$/ do |radio_id_label_or_name|
  page.choose(radio_id_label_or_name)
end

When /^(?:|I )fill in "([^\"]*)" with "([^\"]*)"$/ do |field, value|
  fill_in(field, :with => value)
end

Then /^the "([^\"]*)" field should contain "([^\"]*)"$/ do |field, value|
  field_labeled(field).value.should == value     #=~ /#{value}/
end

When /^I select "([^\"]*)" from "([^\"]*)"$/ do |value, dropdown|
  select(value, from: dropdown)
end

When /^(?:|I )press "([^\"]*)"$/ do |button|
  click_button(button)
end

Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).select(:path, :query).compact.join('?')
  raise "path helper for #{ page name } is undefined - add it to support/paths.rb" if path_to(page_name).blank?
  if defined?(RSpec::Rails)
    path_to(page_name).should eq(current_path)
  else
    # assert_equal blows up with:  undefined method `+' for nil:NilClass (NoMethodError)
    # Checking for Rspec and using those matchers instead works around it . . .
    assert_equal path_to(page_name), current_path
  end
end

Then /^Single column should be labeled MIB$/ do
  page.should have_xpath("//th[@id='single_column_heading'][text()=\"Single (MIB)\"]")
end

Then /^the [Tt]otal [Pp]ayable line should not be present$/ do
  page.should_not have_xpath("//td[@id='total_payable_multi']")
end

# Find a select box by (label) name or id and assert the given text is selected
Then /^"([^"]*)" should have selected value "([^"]*)"$/ do |dropdown, selected_text|
  page.has_select?(dropdown, :selected => selected_text).should == true
end

# Find a select box by (label) name or id and assert the expected option is (not) present among possibly others.
# Passing :with_options does a partial match of items in the set, as well as partial string matches, so this step
# can't distinguish for example "Series 2" from "Series 2 MP".
Then /^"([^"]*)" should( not)? contain option "([^"]*)"$/ do |dropdown, negate, text|
  page.has_select?(dropdown, :with_options => [text]).should == (negate.blank? ? true : false)
end

# Specify an exact set of options for a selector. Options must be comma separated and in the exact order of appearance.
Then /^"([^"]*)" should contain exact options "([^"]*)"$/ do |dropdown, text|
  selectors = text.split(',').map{|s| s.strip}
  page.has_select?(dropdown, :options => selectors).should == true
end

# Find a select box by (label) name or id and assert the expected option is selected
Then /^"([^"]*)" should( not)? be option "([^"]*)"$/ do |dropdown, negate, text|
  page.has_select?(dropdown, :selected => [text]).should == (negate.blank? ? true : false)
end
