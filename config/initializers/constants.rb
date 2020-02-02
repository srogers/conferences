# This works by getting the version out of the environment on Heroku (because there's no git repo there) and getting
# it from the repo locally. The heroku:deploy rake task updates the version in the target environment at deploy time.
APP_VERSION = Rails.env.production? || Rails.env.staging? ? ENV['APP_VERSION'] : (`git describe master --tags`).strip.split('-').first
WEBMASTER_EMAIL = 'srogers1+objectivistmedia@gmail.com'
