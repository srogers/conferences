class Supplement < ApplicationRecord

  mount_uploader :attachment, DocumentUploader

  belongs_to :conference
  belongs_to :creator,    class_name: "User"

  validates :name, :description, :conference_id, presence: true
  validates :url, http_url: true, allow_blank: true

  validate :url_or_attachment

  def url_or_attachment
    errors.add(:url, 'Either URL or attachment must be provided') if url.blank? && attachment.blank?
    errors.add(:url, 'Specify either URL or attachment, but not both') if url.present? && attachment.present?
  end

  # Gives the description with any HTML tags stripped out
  def clean_description
    ActionView::Base.full_sanitizer.sanitize(description)
  end

  def clean_editors_notes
    ActionView::Base.full_sanitizer.sanitize(editors_notes)
  end

  # For attachments, it returns the name with '.pdf' appended, otherwise the plain name.
  def contextual_name
    url.present? ? name : name + '.pdf'
  end

  def event_name
    conference&.name
  end

  def event_date
    if conference.start_date.present?
      ApplicationController.helpers.pretty_date conference.start_date, style: :long
    else
      'n/a'
    end
  end

  # For attachments, it returns the download URL, otherwise the url attribute.
  def contextual_url
    url.present? ? url : Rails.application.routes.url_helpers.download_event_supplement_url(conference_id, id)
  end

  # Hash of human-friendly CSV column names and the methods that get the data
  TITLES_AND_METHODS = {
    'Name'          => :contextual_name,
    'Event'         => :event_name,
    'Event Date'    => :event_date,          # So the sheet can be easily sorted into events/index order
    'URL'           => :contextual_url,
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
end
