class Conference < ApplicationRecord

  belongs_to  :organizer
  belongs_to  :creator,   class_name: "User"

  has_many :presentations
  has_many :speakers, through: :presentations

  has_many :conference_users
  has_many :users, through: :conference_users

  validates :organizer_id, :start_date, :end_date, presence: true

  def location
    "#{city}, #{state}"
  end

  def name
    "#{organizer.abbreviation} #{start_date.year}"
  end
end
