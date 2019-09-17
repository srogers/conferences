class Presentation < ApplicationRecord

  include SortableNames
  include Locations

  belongs_to  :conference
  belongs_to  :creator,   class_name: "User"

  #has_many    :publications, -> { order(:format, :published_on, :notes) },   :dependent => :destroy
  has_many    :presentation_publications,   :dependent => :destroy
  has_many    :publications, through: :presentation_publications

  has_many    :presentation_speakers,       :dependent => :destroy
  has_many    :speakers, through: :presentation_speakers

  has_many    :user_presentations
  has_many    :users, through: :user_presentations  # answers: who's watching this presentation

  validates :name, presence: true
  validate  :unique_per_conference
  # requiring a speaker at create is handled by PresentationsController

  before_save :update_sortable_name

  acts_as_taggable

  mount_uploader :handout, DocumentUploader

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :history]

  # This won't work for standalone presentations, but there isn't anything else meaningful.
  def slug_candidates
    [
      :name,
      [:name, :conference_name]
    ]
  end

  # This is necessary to make Friendly_id generate a new slug when the current name is changed.
  def should_generate_new_friendly_id?
    slug.blank? || name_changed?
  end

  # presentations can exist with duplicate names, but presentation names must be unique within a conference
  def unique_per_conference
    if conference_id.present?
      if id.present?
        duplicate_count = Presentation.where("name = ? AND id != ? AND conference_id = ?", name, id, conference_id).length
      else
        duplicate_count = Presentation.where("name = ? AND conference_id = ?", name, conference_id).length
      end
      errors.add(:conference, "already has a presentation with the same name.") if duplicate_count > 0
    end
  end

  def speaker_names
    speakers.map{|s| s.name}.join(", ")
  end

  def conference_name
    conference&.name
  end

  # Brings over attributes from the conference that also live in presentation to make querying and reporting easier
  def inherit_conference_defaults
    return unless conference.present?
    self.date    = conference.start_date if date.blank?
    self.city    = conference.city if city.blank?
    self.state   = conference.state if state.blank?
    self.country = conference.country if country.blank?
    self.venue   = conference.venue if venue.blank?
    # the caller must save
  end

  def tag_names
    tag_list.join(', ')
  end

  # Gives the description with any HTML tags stripped out
  def clean_description
    ActionView::Base.full_sanitizer.sanitize(description)
  end

  def has_handout?
    handout.present?
  end

  def formats
    publications.map{|p| p.format}.uniq.join(", ")
  end

  def url
    Rails.application.routes.url_helpers.presentation_url(self)
  end

  # Hash of human-friendly CSV column names and the methods that get the data
  TITLES_AND_METHODS = {
    'Name'        => :name,
    'Event'       => :conference_name,
    'Date'        => :date,
    'Venue'       => :venue,
    'City'        => :city,
    'State'       => :state,
    'Country'     => :country,
    'Speakers'    => :speaker_names,
    'Tags'        => :tag_names,
    'Handout'     => :has_handout?,
    'URL'         => :url,
    'Description' => :clean_description
  }

  # DocumentWorker uses this to get the header for generated CSV output
  def self.csv_header
    TITLES_AND_METHODS.keys
  end

  def csv_row
    TITLES_AND_METHODS.values.map{|v| self.send(v)}
  end
end
