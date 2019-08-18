class Publication < ApplicationRecord

  include SortableNames

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
  FORMATS = [ESTORE, YOUTUBE, CAMPUS, FACEBOOK, PRINT, PODCAST, TAPE, CD, VHS, DISK, ONLINE]  # approximately most to least used

  MINUTES = 'minutes'.freeze
  HMS     = 'hh:mm'.freeze
  TIME_FORMATS = [MINUTES, HMS]

  # Presence of duration isn't validated - but in a few cases, it's just not applicable. When it isn't, we need a way to
  # ensure those don't get flagged by the "heart" query as needing attention because duration is blank.
  HAS_DURATION = [ESTORE, YOUTUBE, CAMPUS, FACEBOOK, PODCAST, TAPE, CD, VHS, DISK]

  attr_accessor :ui_duration      # duration in hh:mm or hh:mm:ss or raw minutes

  validates :name, :speaker_names, presence: true
  validates :format, inclusion: { in: FORMATS, message: "%{value} is not a recognized format" }

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

  # Hash of human-friendly CSV column names and the methods that get the data for CSV export
  TITLES_AND_METHODS = {
      'Conference Name'   => :conference_name,
      'Date'              => :conference_date,
      'Presentation Name' => :presentation_name,
      'Format'            => :format,
      'Duration'          => :duration,
      'Notes'             => :notes,
      'Media URL'         => :url,
      'Presentation URL'  => :presentation_url
  }

  # DocumentWorker uses this to get the header for generated CSV output
  def self.csv_header
    TITLES_AND_METHODS.keys
  end

  def csv_row
    TITLES_AND_METHODS.values.map{|v| self.send(v)}
  end
end
