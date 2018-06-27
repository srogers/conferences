class Speaker < ApplicationRecord

  belongs_to  :creator,   class_name: "User"

  has_many :conference_speakers
  has_many :conferences, through: :conference_speakers

end
