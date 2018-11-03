class UserPresentation < ApplicationRecord

  belongs_to  :user
  belongs_to  :presentation

  validates :user_id, :presentation_id, :presence => true

end
