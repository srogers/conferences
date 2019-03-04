class Speaker < ApplicationRecord

  include SortableNames

  belongs_to  :creator,   class_name: "User"

  has_one     :user

  has_many :presentation_speakers,                           :dependent => :destroy
  has_many :presentations, through: :presentation_speakers

  validates :name, presence: true
  validates_uniqueness_of :name, :case_sensitive => false

  before_create :capitalize_name              # do this only once, so the user can fix exceptions like Fred de Cordova
  before_save   :update_sortable_human_name   # always do this unless it's been manually changed

  extend FriendlyId
  friendly_id :name, use: [:slugged, :history]

  mount_uploader :photo, PhotoUploader

  # This is necessary to make Friendly_id generate a new slug when the current name is changed.
  def should_generate_new_friendly_id?
    slug.blank? || name_changed?
  end

  def capitalize_name
    self.name = name.split.map(&:capitalize)*' '
  end

  def update_sortable_name
    # If the sortable name has been updated manually, but the name hasn't, then treat that as a manual override.
    # This is necessary with a few unusual names. If the name is updated, sortable name will have to be updated again,
    # but that is unavoidable.
    logger.debug "name_changed?  #{name_changed?}  sortable_name_changed? #{sortable_name_changed?}"
    return if !name_changed? && sortable_name_changed?
    self.sortable_name = name.split(' ').last
    logger.debug "sortable name now:  #{sortable_name}"
  end

  # Gives the description with any HTML tags stripped out
  def clean_description
    ActionView::Base.full_sanitizer.sanitize(description)
  end

  def has_photo?
    photo.present?
  end

  def url
    Rails.application.routes.url_helpers.speaker_url(self)
  end

  # Hash of human-friendly CSV column names and the methods that get the data
  TITLES_AND_METHODS = {
      'Name'        => :name,
      'Sort Name'   => :sortable_name,
      'Photo'       => :has_photo?,
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
