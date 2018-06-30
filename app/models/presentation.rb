class Presentation < ApplicationRecord

  belongs_to  :conference

  has_many    :publications

  has_many    :presentation_speakers
  has_many    :speakers, through: :presentation_speakers

  def speaker_names
    speakers.map{|s| s.name}.join(", ")
  end

  def conference_name
    conference&.name
  end

  def formats
    publications.map{|p| p.format}.uniq.join(", ")
  end
end
