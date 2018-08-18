class Organizer < ApplicationRecord

  validates :name, :series_name, :abbreviation,  presence: true

  has_many  :conferences

end
