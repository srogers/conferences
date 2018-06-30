class ConferenceUser < ApplicationRecord

  belongs_to  :conference
  belongs_to  :user

  belongs_to  :creator,   class_name: "User"

  validates :conference_id, presence: true
  validates :user_id,       presence: true

end
