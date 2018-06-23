# Provide some sensible matchers for HTTP error codes - why doesn't this exist already?
# In RSpec 1.x / Rails 2.x the actual status is a string like '200 OK'. In RSpec 2.x / Rails 3.x,
# the status is now an integer.
RSpec::Matchers.define :be_forbidden do
  match do |actual|
    actual.status == 403
  end

  failure_message do |actual|
    "expected HTTP status 403 Forbidden but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be #{actual.status}"
  end

  description do
    "be HTTP status 403 Forbidden"
  end
end

# This status will typically be returned when the wrong protocol is used, or a validation error
# happens in a format.js context
RSpec::Matchers.define :be_unacceptable do
  match do |actual|
    actual.status == 406
  end

  failure_message do |actual|
    "expected HTTP status 406 Unacceptable but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be #{actual.status}"
  end

  description do
    "be HTTP status 406 Unacceptable"
  end
end

# This status will typically be returned when save fails - an alternate to 406
RSpec::Matchers.define :be_conflicted do
  match do |actual|
    actual.status == 409
  end

  failure_message do |actual|
    "expected HTTP status 409 Conflict but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be #{actual.status}"
  end

  description do
    "be HTTP status 409 Conflict"
  end
end

# Use this in place of be_success which has the massively unhelpful failure message:
#    expected success? to return true, got false
RSpec::Matchers.define :be_successful do
  match do |actual|
    actual.status == 200
  end

  failure_message do |actual|
    "expected HTTP success status 200 OK but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be success (#{actual.status})"
  end

  description do
    "be HTTP status success (200 OK)"
  end
end

RSpec::Matchers.define :be_created do
  match do |actual|
    actual.status == 201
  end

  failure_message do |actual|
    "expected HTTP status 201 Created but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be #{actual.status}"
  end

  description do
    "be HTTP status 201 Created"
  end
end

# Use this in place of be_redirect which has the massively unhelpful failure message:
#    expected redirect? to return true, got false
# Count anything in the 3xx family as a redirect
RSpec::Matchers.define :be_redirected do
  match do |actual|
    actual.status/100 == 3
  end

  failure_message do |actual|
    "expected HTTP success status 3xx Redirect but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be success (#{actual.status})"
  end

  description do
    "be HTTP status redirect"
  end
end

RSpec::Matchers.define :be_found do
  match do |actual|
    actual.status == 302
  end

  failure_message do |actual|
    "expected HTTP status 302 Found but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be #{actual.status}"
  end

  description do
    "be HTTP status 302 Found (redirect)"
  end
end

RSpec::Matchers.define :be_unfound do
  match do |actual|
    actual.status == 404
  end

  failure_message do |actual|
    "expected HTTP status 404 Not Found but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be #{actual.status}"
  end

  description do
    "be HTTP status 404 Not Found"
  end
end

RSpec::Matchers.define :be_unprocessable_entity do
  match do |actual|
    actual.status == 422
  end

  failure_message do |actual|
    "expected HTTP status 422 Unprocessable Entity but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be #{actual.status}"
  end

  description do
    "be HTTP status 422 Unprocessable Entity"
  end
end

RSpec::Matchers.define :be_not_implemented do
  match do |actual|
    actual.status == 501
  end

  failure_message do |actual|
    "expected HTTP status 501 Not Implemented but got #{actual.status} instead."
  end

  failure_message_when_negated do |actual|
    "expected HTTP status would not be #{actual.status}"
  end

  description do
    "be HTTP status 501 Not Implemented"
  end
end
