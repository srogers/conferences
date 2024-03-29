class Publication < ApplicationRecord

  include SortableNames

  include PublicationsHelper # for unformatting time
  include ApplicationHelper  # for pretty_date()

  has_many    :presentation_publications,   :dependent => :destroy
  has_many    :presentations, through: :presentation_publications

  belongs_to  :creator,   class_name: "User"
  belongs_to  :language

  # Publication doesn't use friendly ID because only editors and admin can see these paths, so they aren't indexed by search engines

  # These are just short word strings and not icons because there aren't good icons for making things like DVD and CD distinct.
  TAPE    = 'Tape'.freeze
  CD      = 'CD'.freeze
  VHS     = 'VHS'.freeze
  DISK    = 'DVD/Blu-ray'.freeze
  LP      = 'Vinyl'.freeze
  CAMPUS  = 'Campus'.freeze
  YOUTUBE = 'YouTube'.freeze      # Is it helpful to make this distinct?
  VIMEO   = 'Vimeo'.freeze        # Is it helpful to make this distinct?  for now, seems like yes
  FACEBOOK = 'FaceBook'.freeze    # Is it helpful to make this distinct?
  INSTAGRAM = 'Instagram'.freeze  # Is it helpful to make this distinct?
  SOUNDCLOUD = 'Soundcloud'.freeze
  PODCAST = 'Podcast'.freeze
  ONLINE  = 'Online'.freeze       # Meant to be an "other" catch-all
  ESTORE  = 'e-Store'.freeze      # This is going away . . . (said Tal in 2018, but it's still there)
  PRINT   = 'Print'.freeze        # Books, pamphlets, Newsletter articles, etc. - physical media
  MOKUJI  = 'Mokuji'.freeze
  FORMATS = [YOUTUBE, CAMPUS, ESTORE, MOKUJI, FACEBOOK, INSTAGRAM, SOUNDCLOUD, VIMEO, PRINT, PODCAST, TAPE, CD, VHS, DISK, LP, ONLINE].freeze  # approximately most to least used

  MINUTES = 'minutes'.freeze
  HMS     = 'hh:mm'.freeze
  TIME_FORMATS = [MINUTES, HMS].freeze

  # Presence of duration isn't validated - but in a few cases, it's just not applicable. When it isn't, we need a way to
  # ensure those don't get flagged by the "heart" query as needing attention because duration is blank.
  HAS_DURATION = [ESTORE, YOUTUBE, CAMPUS, MOKUJI, FACEBOOK, INSTAGRAM, PODCAST, TAPE, CD, VHS, DISK]
  PHYSICAL     = [PRINT, TAPE, CD, VHS, DISK, LP].freeze

  attr_accessor :ui_duration      # duration in hh:mm or hh:mm:ss or raw minutes

  validates :name, :language_id, :speaker_names, presence: true
  validates :format, inclusion: { in: FORMATS, message: "%{value} is not a recognized format" }
  validates :ui_duration, duration_format: true
  validates_numericality_of :duration, greater_than_or_equal_to: 0, allow_blank: true

  before_validation :format_duration, :clean_url

  before_save :update_sortable_name

  # Move the contents of #ui_duration into #duration as raw seconds
  def format_duration
    if ui_duration.present? && ui_duration&.respond_to?(:include?)
      if ui_duration == 'N/A'
        self.duration = nil
        self.ui_duration = ''
      elsif ui_duration.tr('0-9', '').length > 0        # expect there is some delimiter
        delimiter = ui_duration.tr('0-9', '').first     # the typo for colon has to be consistent, 01;18/05 will fail
        ui_duration.gsub!(delimiter, ':')               # whatever the non-digit was, make it a colon
        self.duration =  unformatted_time(ui_duration)  # expect hh:mm or hh:mm:ss format
      else
        self.duration = ui_duration.to_i                # expect raw minutes format
      end
    end
  end

  # Strip off marketing/tracking params and remove video start time params from YouTube and Vimeo
  def clean_url
    return  #   Not yet implemented
  end

  def has_duration?
    HAS_DURATION.include? format
  end

  # For determining which items can be in inventory at all. We're not tracking ARI inventory for things like
  # YouTube, Campus, E-store, etc. which are probably retained at the ARI in some form. Just physical media.
  def physical?
    PHYSICAL.include? format
  end

  def ari_inventory_text
    physical? ? ari_inventory : 'n/a'
  end

  # synthesize a description for FB sharing
  def description
    text = ['A']
    text << [duration, 'minute'] if duration.present?
    text << [format, 'publication']
    text << [ 'from', pretty_date(published_on) ] if published_on.present?
    text << ['by', presentations.first.speaker_names] if presentations.present?
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

  def language_name
    language&.name
  end

  def language_abbreviation
    language&.abbreviation
  end

  def publication_url
    Rails.application.routes.url_helpers.publication_url(self)
  end

  # The "clean" methods give the contents of rich-text fields with any HTML tags stripped out (for CSV export)
  def clean_description
    ActionView::Base.full_sanitizer.sanitize(description)
  end

  def clean_editors_notes
    ActionView::Base.full_sanitizer.sanitize(editors_notes)
  end

  def clean_details
    ActionView::Base.full_sanitizer.sanitize(details)
  end

  # Hash of human-friendly CSV column names and the methods that get the data for CSV export
  TITLES_AND_METHODS = {
      'Name'              => :name,
      'Event Names'       => :event_names,
      'Speaker Names'     => :available_speaker_names,
      'Published On'      => :published_on,
      'Format'            => :format,
      'Duration'          => :duration,
      'Publisher'         => :publisher,
      'ARI Inventory'     => :ari_inventory_text,  # Shows N/A for non-physical items, which lines up with the UI
      'Notes'             => :notes,               # multi-part info, and details that distinguish one copy from another
      'Media URL'         => :url,
      'Presentation URL'  => :publication_url,
      'Description'       => :clean_description,   # contains a generated one-liner intended for FB meta data
      'Details'           => :clean_details,       # contains supplemental info and references
      'Editors Notes'     => :clean_editors_notes, # references and addresses potential ambiguities and unknowns
  }

  # DocumentWorker uses this to get the header for generated CSV output
  def self.csv_header
    TITLES_AND_METHODS.keys
  end

  def csv_row
    TITLES_AND_METHODS.values.map{|v| self.send(v)}
  end
end
