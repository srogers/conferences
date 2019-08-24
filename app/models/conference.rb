class Conference < ApplicationRecord

  include Locations

  require 'states'  # seems like it shouldn't be necessary to load this explicitly, but it is
  include States

  belongs_to  :organizer
  belongs_to  :creator,   class_name: "User"

  has_many :presentations                       # currently, conferences with presentations can't be destroyed
  has_many :speakers, through: :presentations

  has_many :conference_users,                   :dependent => :destroy
  has_many :users, through: :conference_users

  CONFERENCE = 'Conference'.freeze
  DEBATE     = 'Debate'.freeze
  SERIES     = 'Series'.freeze
  SPEECH     = 'Speech'.freeze
  EVENT_TYPES = [CONFERENCE, DEBATE, SERIES, SPEECH, ].freeze

  validates :event_type, inclusion: { in: EVENT_TYPES, message: "%{value} is not a recognized event type" }
  validates :name, :organizer_id, :start_date, :end_date, presence: true
  validate  :starts_before_ending
  validate  :us_state_existence

  before_validation :set_default_name, if: Proc.new {|c| c.name.blank? }  # only set the default if the user blanked it
  before_save       :update_default_name

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :history]

  def slug_candidates
    [
      :name,
      [:name, :city]
    ]
  end

  # This is necessary to make Friendly_id generate a new slug when the current name is changed.
  def should_generate_new_friendly_id?
    slug.blank? || name_changed?
  end

  def starts_before_ending
    errors.add(:end_date, 'End date has to be after or the same as start date') if start_date.present? && end_date.present? && start_date > end_date
  end

  def set_default_name
    # Usually an adequate name - like "OCON 2015" or "TOS-CON 2018", but not great for special events.
    # When the default name is not great, the user just has to change it.
    self.name = default_name(organizer) if name.blank?
  end

  # reset the default name if the conference is using the default name, but leave it alone if it has been manually modified
  def update_default_name
    if will_save_change_to_organizer_id?
      previous_organizer = Organizer.where(abbreviation: name.split(" ").first).first
      old_default_name = default_name(previous_organizer)
      use_default = name == old_default_name
    else
      use_default = name.blank?
    end
    self.name = default_name(organizer) if use_default
  end

  # This is referenced by itself in conference/index, so it isn't private
  def date_span
    # Using pretty_date here to avoid having to deal with strftime or build a lookup table for month names
    start_text = "#{ ApplicationController.helpers.pretty_date start_date, style: start_date.year == end_date.year ? :yearless : ''}"
    if start_date == end_date
      end_text = ", #{ end_date.year}"
    else
      end_text = "#{ end_date.day }, #{ end_date.year }"
      if start_date.month != end_date.month || start_date.year != end_date.year
        end_text = "#{ I18n.l(end_date, format: "%b") } " + end_text
      end
      end_text = "-" + end_text
    end
    return start_text + end_text
  end

  def url
    Rails.application.routes.url_helpers.conference_url(self)
  end

  def has_program?
    program_url.present?
  end

  def future?
    start_date > Date.today
  end

  # Hash of human-friendly CSV column names and the methods that get the data
  TITLES_AND_METHODS = {
      'Name'        => :name,
      'Start'       => :start_date,
      'End'         => :end_date,
      'Venue'       => :venue,
      'City'        => :city,
      'State'       => :state,
      'Country'     => :country,
      'Completed'   => :completed,
      'Program'     => :has_program?,
      'URL'         => :url
  }

  # DocumentWorker uses this to get the header for generated CSV output
  def self.csv_header
    TITLES_AND_METHODS.keys
  end

  def csv_row
    TITLES_AND_METHODS.values.map{|v| self.send(v)}
  end

  private

  # Get the default name for a given organizer, which may not be the current one
  def default_name(an_organizer)
    "#{an_organizer&.abbreviation} #{start_date&.year}"
  end

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
