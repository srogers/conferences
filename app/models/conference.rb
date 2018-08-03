class Conference < ApplicationRecord

  require 'states'  # seems like it shouldn't be necessary to load this explicitly, but it is
  include States

  belongs_to  :organizer
  belongs_to  :creator,   class_name: "User"

  has_many :presentations                       # currently, conferences with presentations can't be destroyed
  has_many :speakers, through: :presentations

  has_many :conference_users,                   :dependent => :destroy
  has_many :users, through: :conference_users

  validates :name, :organizer_id, :start_date, :end_date, presence: true
  validate  :starts_before_ending
  validate  :us_state_existence

  before_validation :set_default_name

  extend FriendlyId
  friendly_id :name, use: :slugged

  def starts_before_ending
    errors.add(:end_date, 'End date has to be after or the same as start date') if start_date.present? && end_date.present? && start_date > end_date
  end

  def us_state_existence
    return true unless country == 'US'
    errors.add(:state, 'Use the standard two-letter postal abbreviation for US states.') unless States::STATES.map{|s| s[0]}.include?(state)
  end

  def set_default_name
    # Usually an adequate name - like "OCON 2015" or "TOS-CON 2018", but not great for special events.
    # When the default name is not great, the user just has to change it.
    self.name = "#{organizer&.abbreviation} #{start_date&.year}" if name.blank?
  end

  # Uses translations provided by country_select gem to convert the country_code to country name
  def country_name
    if country.present?
      country_object = ISO3166::Country[country]
      country_object.translations[I18n.locale.to_s] || country_object.name
    else
      "n/a"
    end
  end

  def location(show_country=false)
    elements = [city.presence, state.presence]
    elements << [country_name.presence] if show_country.to_s == 'full'
    elements << [country.presence] if show_country.to_s == 'short'
    elements.compact.join(', ')
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
