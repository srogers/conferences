class PresentationPublication < ApplicationRecord

  belongs_to  :presentation
  belongs_to  :publication

  belongs_to  :creator,   class_name: "User"

  validates :presentation_id, presence: true
  validates :publication_id, presence: true

end
