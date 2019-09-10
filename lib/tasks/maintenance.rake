# A place to hold data maintenance tasks, including tasks that service a one-time data upgrade and should
# likely be subsequently deleted.
namespace :db do
  desc 'A data migration task to move to the rule that presentations always have dates when available - blank means unknown.'
  task :set_presentation_date => :environment do
    puts
    puts "handling presentations . . ."
    count = 0
    Presentation.find_each do |presentation|
      next if presentation.date.present?
      next unless presentation.conference.present?
      presentation.date = presentation.conference.start_date
      presentation.save
      if count % 100 == 0
        print "." # I'm not hung!
        STDOUT.flush
      end
      if presentation.errors.present?
        puts # get on a new line
        puts "Failed to save presentation ID #{ presentation.id} - #{ presentation.errors.full_messages }"
      end
      count += 1
    end
    puts
  end
end
