# A place to hold data maintenance tasks that service a one-time data upgrade and should likely be subsequently deleted.
# Non-destructively checking data integrity and recurring issues is handled in db:norton

namespace :db do
  # This can serve as an example for a task that re-saves every instance of a model
  # to fire any new on_save or after_save hooks and record any failures.
  desc 'A data migration task to move to the rule that presentations always have dates/locations when available - blank means unknown.'
  task :set_presentation_defaults => :environment do
    puts
    puts "handling presentations . . ."
    count = 0
    Presentation.find_each do |presentation|
      presentation.inherit_conference_defaults
      presentation.save
      if presentation.errors.present?
        puts # get on a new line
        puts "Failed to save presentation ID #{ presentation.id} - #{ presentation.errors.full_messages }"
      end
      count += 1
      if count % 100 == 0
        print "." # I'm not hung!
        STDOUT.flush
      end
    end
    puts
  end

  # This might be a keeper, in case the problem ever comes back due to switching settings
  desc 'A data maintenance task to catch up legacy accounts to the new standard where all are approved.'
  task :approve_all_accounts => :environment do
    raise "Don't run this while approval is required" if Setting.require_account_approval?
    puts
    puts "collecting users . . ."
    count = 0
    User.find_each do |user|
      # Don't change the state of users waiting on approval, but approve the ones already active
      next unless user.active? and !user.approved?
      user.approve!
      if user.errors.present?
        puts # get on a new line
        puts "Failed to save user ID #{ user.id} - #{ user.errors.full_messages }"
      end
      count += 1
      if count % 100 == 0
        print "." # I'm not hung!
        STDOUT.flush
      end
    end
    puts "updated #{ count } users"
    puts
  end
end
