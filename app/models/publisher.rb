class Publisher < ApplicationRecord

  belongs_to :creator, class_name: 'User'

  # does not have_many :publications
  # In the first iteration, publishers just stand along side publications. The names just serve to mostly standardize
  # publishers, but relation is not by ID - publishers can be anything.
  # TODO - if it seems like publisher develops into a coherent, manageable set, then make it a first-class relationship.

  validates :name, presence: true, uniqueness: true

end
