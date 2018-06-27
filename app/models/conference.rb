class Conference < ApplicationRecord

  belongs_to  :organizer
  belongs_to  :creator,   class_name: "User"

  has_many :conference_speakers
  has_many :speakers, through: :conference_speakers

  validates :organizer_id, presence: true

  def location
    "#{city}, #{state}"
  end

  def name
    "#{organizer.abbreviation} #{start_date.year}"
  end

  def full_name
    "#{organizer.series_name.singularize} #{start_date.year}"
  end
end
