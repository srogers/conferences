class Conference < ApplicationRecord

  belongs_to  :organizer
  belongs_to  :creator,   class_name: "User"

  has_many :presentations                       # currently, conferences with presentations can't be destroyed
  has_many :speakers, through: :presentations

  has_many :conference_users,                   :dependent => :destroy
  has_many :users, through: :conference_users

  validates :organizer_id, :start_date, :end_date, presence: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def location
    [city, state].compact.join(', ')
  end

  # Currently only conference/index uses this because the date/city is shown with the name, making fully_qualified_name redundant.
  # TODO - this is part of the overall jankyness of special events - to work, organizer.series_name has to be cleverly selected.
  def short_name
    if special_event?
      "#{ organizer.series_name.singularize }"
    else
      name
    end
  end

  # Returns the minimum clearly distinct name for the conference.
  # This is used by presentations/new when picking a conference from scratch, as well as pre-populating the field.
  # All values have to be treated as possibly nil, because FriendlyId can call the name method at unexpected times.
  def name
    if special_event?
      # returns something like: "Special Event, Sep 12, 2006 - Irvine, CA"
      fully_qualified_name
    else
      # Usually an adequate name - like "OCON 2015" or "TOS-CON 2018", but not great for special events
      "#{organizer&.abbreviation} #{start_date&.year}"
    end
  end

  # This is referenced by itself in conference/index, so it isn't private
  def date_span
    # Using pretty_date here to avoid having to deal with strftime or build a lookup table for month names
    start_text = "#{ ApplicationController.helpers.pretty_date start_date, style: :yearless }"
    if start_date == end_date
      end_text = ", #{ end_date.year}"
    else
      end_text = "#{ end_date.day }, #{ end_date.year }"
      if start_date.month != end_date.month
        end_text = "#{ I18n.l(Time.now, format: "%B") } " + end_text
      end
      end_text = "-" + end_text
    end
    return start_text + end_text
  end

  private

  # This is necessary because there isn't currently a place for events to have a distinct name, and this is confusing
  # when selecting the conference from autocomplete in presentation/create.
  # TODO - Maybe conferences should have an explicit name that is initialized from the organizer data, which could be modified for special events.
  def special_event?
    # this is pretty janky, because it relies on the organizer having "Event" for the series abbreviation
    # TODO - maybe conference should have an explicit special event designator, or allow explicit titles to be assigned
    #        and detect special events based on whether the title has been modified from the default.
    organizer&.abbreviation == "Event"
  end

  # Necessary because of special events.
  def fully_qualified_name
    "#{ organizer.series_name.singularize }, #{ date_span } – #{ location }"
  end
end
