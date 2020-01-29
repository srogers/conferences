class Conference < ApplicationRecord

  include Locations

  require 'states'  # seems like it shouldn't be necessary to load this explicitly, but it is
  include States

  belongs_to  :organizer
  belongs_to  :creator,   class_name: "User"

  has_many :presentations                       # currently, conferences with presentations can't be destroyed
  has_many :supplements
  has_many :speakers, through: :presentations

  has_many :conference_users,                   :dependent => :destroy
  has_many :users, through: :conference_users

  CONFERENCE = 'Conference'.freeze
  DEBATE     = 'Debate'.freeze
  INTERVIEW  = 'Interview'.freeze
  SERIES     = 'Series'.freeze
  SPEECH     = 'Speech'.freeze
  TOUR       = 'Tour'.freeze
  EVENT_TYPES = [CONFERENCE, DEBATE, INTERVIEW, SERIES, SPEECH, TOUR].freeze

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

  # This is referenced directly in conference/index and used in PDF generation, so it isn't private
  def date_span(options={compact: false})
    if options[:compact]
      month_only = :yearless_s
      full       = :pretty
    else
      month_only = :yearless
      full       = :pretty_full
    end
    # Using pretty_date here to avoid having to deal with strftime or build a lookup table for month names
    start_text = "#{ ApplicationController.helpers.pretty_date start_date, style: start_date.year == end_date.year ? month_only : full}"
    if start_date == end_date
      end_text = ", #{ end_date.year}"
    else
      end_date_day = end_date.day < 10 ? '0' + end_date.day.to_s : end_date.day
      end_text = "#{ end_date_day }, #{ end_date.year }"
      if start_date.month != end_date.month || start_date.year != end_date.year
        end_text = "#{ I18n.l(end_date, format: "%b") } " + end_text
      end
      end_text = "-" + end_text
    end
    return start_text + end_text
  end

  def url
    Rails.application.routes.url_helpers.event_url(self)
  end

  def future?
    start_date > Date.today
  end

  # The "clean" methods give the contents of rich-text fields with any HTML tags stripped out (for CSV export)
  def clean_description
    ActionView::Base.full_sanitizer.sanitize(description)
  end

  def clean_editors_notes
    ActionView::Base.full_sanitizer.sanitize(editors_notes)
  end

  # Hash of human-friendly CSV column names and the methods that get the data
  TITLES_AND_METHODS = {
      'Name'        => :name,
      'Type'        => :event_type,
      'Start'       => :start_date,
      'End'         => :end_date,
      'Venue'       => :venue,
      'City'        => :city,
      'State'       => :state,
      'Country'     => :country,
      'Completed'   => :completed,
      'URL'         => :url,
      'Description'   => :clean_description,
      'Editors Notes' => :clean_editors_notes
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
end
