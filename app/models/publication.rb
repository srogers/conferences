class Publication < ApplicationRecord

  # belongs_to  :presentation
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

  # Presence of duration isn't validated - but in a few cases, it's just not applicable. When it isn't, we need a way to
  # ensure those don't get flagged by the "heart" query as needing attention because duration is blank.
  HAS_DURATION = [ESTORE, YOUTUBE, CAMPUS, FACEBOOK, PODCAST, TAPE, CD, VHS, DISK]

  validates :format, inclusion: { in: FORMATS, message: "%{value} is not a recognized format" }

  # Methods used to support CSV export
  def presentation_url
    presentation&.url
  end

  def presentation_name
    presentation&.name
  end

  def conference_name
    presentation&.conference_name
  end

  def conference_date
    presentation&.conference&.start_date
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
