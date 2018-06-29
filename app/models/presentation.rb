class Presentation < ApplicationRecord

  belongs_to  :speaker
  belongs_to  :conference

  has_many    :publications

  validates :speaker_id, presence: true

  def speaker_name
    speaker&.name
  end

  def formats
    publications.map{|p| p.format}.uniq.join(", ")
  end
end
