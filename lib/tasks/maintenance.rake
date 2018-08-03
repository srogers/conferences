# A place to hold data maintenance tasks, including tasks that service a one-time data upgrade and should
# likely be subsequently deleted.
namespace :db do
  desc 'A data migration task to bring users and countries up to speed with a default (which will be right in almost all cases)'
  task :set_countries => :environment do
    puts
    puts "handling users . . ."
    User.find_each do |user|
      user.update_attribute :country, 'US' if user.country.blank?
    end

    puts "handling conferences . . ."
    Conference.find_each do |conference|
      conference.update_attribute :country, 'US' if conference.country.blank?
    end
    puts
  end

  desc 'Sets initial values for the new Conference name attribute.'
  task :set_conference_names => :environment do
    puts
    puts "handling conferences . . ."
    Conference.find_each do |conference|
      # Set up the same names that were being dynamically generated
      if conference.organizer&.abbreviation == "Event"
        name = "#{ conference.organizer.series_name.singularize }, #{ conference.date_span } – #{ conference.location }"
      else
        name = "#{ conference.organizer&.abbreviation } #{ conference.start_date&.year }"
      end
      conference.update_attribute :name, name if conference.name.blank?
    end
    puts
  end
end
