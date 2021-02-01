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

  # For #481 - a one-shot task that can be deleted once it's run everywhere.  Safe to re-run
  desc 'A data migration task to change "LP Record" to "Vinyl"'
  task :set_vinyl_name => :environment do
    puts
    puts "handling publications . . ."
    count = 0
    updated = 0
    publications = Publication.where(format: "LP Record")
    publications.each do |publication|
      count += 1
      publication.format = "Vinyl"
      publication.save
      if publication.errors.present?
        puts # get on a new line
        puts "Failed to save publication ID #{ publication.id} - #{ publication.errors.full_messages }"
      else
        updated += 1
      end
      if count % 10 == 0
        print "." # I'm not hung!
        STDOUT.flush
      end
    end
    puts "found #{count}, updated #{updated} publication formats"
  end

  # This is primarily for numbering existing events after adding episode numbers - but it might stick around for cases
  # where it turns out something needs to be numbered but wasn't initially set up that way.
  desc "A data migration/maintenance task to number the presentations within an event. Specify an event with event_id=name-slug"
  task :number_presentations => :environment do
    event_id = ENV['event_id'] || ENV['EVENT_ID']
    raise "specify the event to number with event_id=name-slug" if event_id.blank?
    event = Conference.friendly.find event_id

    puts
    puts "handling presentations . . ."
    count = 0
    presentations = event.presentations.order(:created_at)
    presentations.each do |presentation|
      count += 1
      presentation.episode = count
      presentation.save
      if presentation.errors.present?
        puts # get on a new line
        puts "Failed to save presentation ID #{ presentation.id} - #{ presentation.errors.full_messages }"
      end
      print "." # I'm not hung!
      STDOUT.flush
    end
    event.use_episodes = true
    event.save!
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

  # Set initial values for virtual and multiple conference cities, to switch to the regime of having these managed
  # by the model, so they show up correctly in reports. Probably just a one-shot task. Might keep in case it needs reversing.
  desc 'A data maintenance task set Virtual and Multiple event cities to those values.'
  task :set_multiple_virtual_event_cities => :environment do
    puts "updating Multiple"
    ActiveRecord::Base.connection.execute("UPDATE conferences SET city = 'Multiple' WHERE venue = 'Multiple'")
    puts "updating Virtual"
    ActiveRecord::Base.connection.execute("UPDATE conferences SET city = 'Virtual' WHERE venue = 'Virtual'")
    puts "done"
  end

end
