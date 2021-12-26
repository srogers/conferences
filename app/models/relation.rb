class Relation < ApplicationRecord

  belongs_to  :presentation
  belongs_to  :related,   class_name: "Presentation"

  validates :presentation_id, presence: true
  validates :related_id, presence: true
  validates :kind, presence: true

  ABOUT = 'about'
  RECOMMENDED = 'recommended'

  RELATIONSHIP_TYPES = {
    ABOUT       => :about,            # Primary is about related
    RECOMMENDED => :recommended       # If you like primary, then you might like related
  }

  def self.about_this(presentation)
    Presentation.where("id in (SELECT presentation_id FROM relations WHERE kind = 'about' AND related_id = ?)", presentation.id)
  end

  def self.this_is_about(presentation)
    Presentation.where("id in (SELECT related_id FROM relations WHERE kind = 'about' AND presentation_id = ?)", presentation.id)
  end
end
