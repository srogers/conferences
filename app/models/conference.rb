class Conference < ApplicationRecord

  belongs_to  :organizer
  belongs_to  :creator,   class_name: "User"

  has_many :presentations                       # currently, conferences with presentations can't be destroyed
  has_many :speakers, through: :presentations

  has_many :conference_users,                   :dependent => :destroy
  has_many :users, through: :conference_users

  validates :organizer_id, :start_date, :end_date, presence: true

  def location
    [city, state].join(', ')
  end

  def name
    "#{organizer.abbreviation} #{start_date.year}"
  end
end
