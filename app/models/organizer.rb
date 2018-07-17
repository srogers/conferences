class Organizer < ApplicationRecord

  validates :name,       presence: true

  has_many  :conferences

end
