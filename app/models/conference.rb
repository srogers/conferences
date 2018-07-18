class Conference < ApplicationRecord

  belongs_to  :organizer
  belongs_to  :creator,   class_name: "User"

  has_many :presentations                       # currently, conferences with presentations can't be destroyed
  has_many :speakers, through: :presentations

  has_many :conference_users,                   :dependent => :destroy
  has_many :users, through: :conference_users

  validates :organizer_id, :start_date, :end_date, presence: true

  def location
    [city, state].compact.join(', ')
  end

  # Usually an adequate name - like "OCON 2015" or "TOS-CON 2018", but not great for special events
  def name
    "#{organizer.abbreviation} #{start_date.year}"
  end

  # This is necessary because there isn't currently a place for events to have a distinct name, and this is confusing
  # when selecting the conference from autocomplete in presentation/create.
  # TODO - Maybe conferences should have an explicit name that is initialized from the organizer data, which could be modified for special events.
  def special_event?
    # this is pretty janky, because it relies on the organizer having "Event" for the series abbreviation
    # TODO - maybe conference should have an explicit special event designator, or allow explicit titles to be assigned
    #        and detect special events based on whether the title has been modified from the default.
    organizer.abbreviation == "Event"
  end
end
