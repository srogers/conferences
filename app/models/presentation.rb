class Presentation < ApplicationRecord

  belongs_to  :conference
  belongs_to  :creator,   class_name: "User"

  has_many    :publications,            :dependent => :destroy

  has_many    :presentation_speakers,   :dependent => :destroy
  has_many    :speakers, through: :presentation_speakers

  validates :name, presence: true
  validate  :unique_per_conference

  acts_as_taggable

  extend FriendlyId
  friendly_id :name, use: :slugged

  mount_uploader :handout, DocumentUploader

  # presentations can exist with duplicate names, but presentation names must be unique within a conference
  def unique_per_conference
    if conference_id.present?
      if id.present?
        duplicate_count = Presentation.where("name = ? AND id != ? AND conference_id = ?", name, id, conference_id).length
      else
        duplicate_count = Presentation.where("name = ? AND conference_id = ?", name, conference_id).length
      end
      errors.add(:conference, "already has a presentation with the same name.") if duplicate_count > 0
    end
  end

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
