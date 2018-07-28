class Presentation < ApplicationRecord

  belongs_to  :conference
  belongs_to  :creator,   class_name: "User"

  has_many    :publications,            :dependent => :destroy

  has_many    :presentation_speakers,   :dependent => :destroy
  has_many    :speakers, through: :presentation_speakers

  validates :name, presence: true

  acts_as_taggable

  extend FriendlyId
  friendly_id :name, use: :slugged

  mount_uploader :handout, DocumentUploader

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
