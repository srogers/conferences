# A place to hold data maintenance tasks, including tasks that service a one-time data upgrade and should
# likely be subsequently deleted.

namespace :db do
  desc "Initializes speaker bio date to the date of the latest conference (assuming it came from that program). Won't alter existing dates"
  task :set_speaker_bio_dates => :environment do
    puts
    puts "handling speakers . . ."
    count = 0
    changed = 0
    Speaker.find_each do |speaker|
      next if speaker.description.blank? || speaker.bio_on.present?
      count += 1

      conference = speaker.conferences.sort_by(&:start_date).last
      if conference.present? # This should almost always be true, but has to be checked
        changed += 1
        speaker.bio_on = conference.start_date
        speaker.save
        puts "failed to save speaker ID #{ speaker.id }  '#{ speaker.name }' - #{speaker.errors.full_messages}" if speaker.errors.present?
      else
        puts "no conferences for #{speaker.name} - might be an issue"
      end
    end
    puts
    puts "looked at #{count} speakers, set #{changed} bio dates."
  end

  desc "Sets publication date when it can be unambiguously inferred from conference. Lists ones that can't be fixed. Can be re-run."
  task :set_publication_dates => :environment do
    puts
    puts "handling presentations . . ."
    count = 0
    changed = 0
    Publication.find_each do |publication|

      next if publication.published_on.present?

      count += 1
      # First, flag it for manual fix if it's from YouTube - because we can get that info
      if publication.format ==  Publication::YOUTUBE
        puts
        puts "manually fix publication ID #{ publication.id } '#{ publication.name }' manually - look up publication date on YouTube."
        next
      end

      # Next, try to deduce it from the conference
      if publication.presentations.present?
        dates = publication.presentations.map{|p| p&.conference&.start_date}.compact.uniq
        if dates.length == 1
          changed += 1
          #puts "assign publication date of: #{ dates.first + 1.year }"
          publication.published_on = dates.first + 1.year
          publication.editors_notes = [publication.editors_notes, 'publication date estimated based on conference'].join("\n")
          publication.save
          puts "failed to save publication ID #{ publication.id }  '#{ publication.name }' - #{publication.errors.full_messages}" if publication.errors.present?
        elsif dates.length > 1
          # puts "#{ publication.presentations.length }  #{ publication.presentations.map{|p| p&.conference&.start_date}.compact.join(',') } "
          puts "manually fix publication ID #{ publication.id }  '#{ publication.name }' - pick among conference dates: #{dates.join(', ')}"
        else
          puts "manually fix publication ID #{ publication.id }  '#{ publication.name }' - can't deduce a date for it."
        end
      end

    end
    puts
    puts "looked at #{count} publications, changed #{changed}."
  end

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
