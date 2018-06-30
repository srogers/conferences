class Speaker < ApplicationRecord

  belongs_to  :creator,   class_name: "User"

  has_many :presentation_speakers
  has_many :presentations, through: :presentation_speakers

  validates :name, presence: true
  validates_uniqueness_of :name, :case_sensitive => false

  before_save :update_sortable_name

  def update_sortable_name
    self.sortable_name = name.split(' ').last
  end
end
