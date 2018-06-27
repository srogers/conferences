class Presentation < ApplicationRecord

  belongs_to  :speaker
  belongs_to  :conference

  validates :speaker_id, presence: true

end