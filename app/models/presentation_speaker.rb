class PresentationSpeaker < ApplicationRecord

  belongs_to  :presentation
  belongs_to  :speaker

  belongs_to  :creator,   class_name: "User"

  validates :presentation_id, presence: true
  validates :speaker_id, presence: true

end
