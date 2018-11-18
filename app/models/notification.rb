class Notification < ApplicationRecord

  validates :user_presentation_id, :presentation_publication_id,  presence: true

  belongs_to :presentation_publication
  belongs_to :user_presentation

end
