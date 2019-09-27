class Publication < ApplicationRecord

  include SortableNames

  include PublicationsHelper # for unformatting time
  include ApplicationHelper  # for pretty_date()

  has_many    :presentation_publications,   :dependent => :destroy
  has_many    :presentations, through: :presentation_publications

  belongs_to  :creator,   class_name: "User"

  # Publication doesn't use friendly ID because only editors and admin can see these paths, so they aren't indexed by search engines

  # These are just short word strings and not icons because there aren't good icons for making things like DVD and CD distinct.
  TAPE    = 'Tape'
  CD      = 'CD'
  VHS     = 'VHS'
  DISK    = 'DVD/Blu-ray'
  CAMPUS  = 'Campus'
  YOUTUBE = 'YouTube'      # Is it helpful to make this distinct?
  FACEBOOK = 'FaceBook'    # Is it helpful to make this distinct?
  PODCAST = 'Podcast'
  ONLINE  = 'Online'       # Meant to be an "other" catch-all
  ESTORE  = 'e-Store'      # This is going away . . .
  PRINT   = 'Print'        # Books, pamphlets, Newsletter articles, etc. - physical media
  FORMATS = [YOUTUBE, CAMPUS, ESTORE, FACEBOOK, PRINT, PODCAST, TAPE, CD, VHS, DISK, ONLINE]  # approximately most to least used

  MINUTES = 'minutes'.freeze
  HMS     = 'hh:mm'.freeze
  TIME_FORMATS = [MINUTES, HMS]

  # Presence of duration isn't validated - but in a few cases, it's just not applicable. When it isn't, we need a way to
  # ensure those don't get flagged by the "heart" query as needing attention because duration is blank.
  HAS_DURATION = [ESTORE, YOUTUBE, CAMPUS, FACEBOOK, PODCAST, TAPE, CD, VHS, DISK]

  attr_accessor :ui_duration      # duration in hh:mm or hh:mm:ss or raw minutes

  validates :name, :speaker_names, presence: true
  validates :format, inclusion: { in: FORMATS, message: "%{value} is not a recognized format" }
  validates_numericality_of :duration, greater_than_or_equal_to: 0, allow_blank: true
  validates :ui_duration, duration_format: true

  before_validation :format_duration

  before_save :update_sortable_name

  # Move the contents of #ui_duration into #duration as raw seconds
  def format_duration
    if ui_duration.present? && ui_duration&.respond_to?(:include?)
      if ui_duration&.include?(':')
        self.duration =  unformatted_time(ui_duration)  # expect hh:mm or hh:mm:ss format
      else
        self.duration = ui_duration.to_i                # expect raw minutes format
      end
    end
  end

  def has_duration?
    HAS_DURATION.include? format
  end

  # synthesize a description for FB sharing
  def description
    text = ['A']
    text << [duration, 'minute'] if duration.present?
    text << [format, 'publication']
    text << ['by', presentations.first.speaker_names] if presentations.present?
    text << [ 'on', pretty_date(published_on) ] if published_on.present?
    text.join(' ')
  end

  # Inefficient - use this only for PDF/CSV export. Different from the similarly named helper, which produces HTML
  def event_names
    presentations.map{|p| p.conference_name}.join(', ')
  end

  # Collects the speakers from associated presentations if possible (probably most accurate), otherwise falls back to speaker names
  # Inefficient - use this only for PDF/CSV export.
  def available_speaker_names
    if presentations.present?
      presentations.map{|p| p.speaker_names}.flatten.uniq.join(', ')
    else
      speaker_names
    end
  end

  def publication_url
    Rails.application.routes.url_helpers.publication_url(self)
  end

  # Hash of human-friendly CSV column names and the methods that get the data for CSV export
  TITLES_AND_METHODS = {
      'Name'              => :name,
      'Event Names'       => :event_names,
      'Speaker Names'     => :available_speaker_names,
      'Published On'      => :published_on,
      'Format'            => :format,
      'Duration'          => :duration,
      'Notes'             => :notes,
      'Media URL'         => :url,
      'Presentation URL'  => :publication_url
  }

  # DocumentWorker uses this to get the header for generated CSV output
  def self.csv_header
    TITLES_AND_METHODS.keys
  end

  def csv_row
    TITLES_AND_METHODS.values.map{|v| self.send(v)}
  end
end
