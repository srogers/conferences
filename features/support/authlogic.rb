# It might be possible to speed things up by skipping literal login - couldn't get it to work
# see:  http://laserlemon.com/blog/2011/05/20/make-authlogic-and-cucumber-play-nice/
# and:  http://stackoverflow.com/questions/25533307/authlogic-activation-in-cucumber
#
#require "authlogic/test_case"
#World(Authlogic::TestCase)
#ApplicationController.skip_before_filter :activate_authlogic

#Before do
#  activate_authlogic
#end
