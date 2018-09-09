class Presentation < ApplicationRecord

  belongs_to  :conference
  belongs_to  :creator,   class_name: "User"

  #has_many    :publications, -> { order(:format, :published_on, :notes) },   :dependent => :destroy
  has_many    :presentation_publications,   :dependent => :destroy
  has_many    :publications, through: :presentation_publications

  has_many    :presentation_speakers,   :dependent => :destroy
  has_many    :speakers, through: :presentation_speakers

  validates :name, presence: true
  validate  :unique_per_conference
  # requiring a speaker at create is handled by PresentationsController

  before_save :update_sortable_name

  acts_as_taggable

  extend FriendlyId
  friendly_id :name, use: [:slugged, :history]

  mount_uploader :handout, DocumentUploader

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

  def update_sortable_name
    name_parts = name.split(' ')
    if ["A", "An", "The"].include? name_parts[0]
      name_parts.delete_at(0)
      self.sortable_name = name_parts.join(" ")
    else
      self.sortable_name = name
    end
    self.sortable_name[0] = '' if ['"', "'"].include? name[0] # probably other characters will turn up that should be included
  end

  def speaker_names
    speakers.map{|s| s.name}.join(", ")
  end

  def conference_name
    conference&.name
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
    'Conference'  => :conference_name,
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
