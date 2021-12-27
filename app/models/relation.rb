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

  # Converts a list of relations to a list of presentations from the relation.presentation.
  # Controller gets this_is_about()
  def self.source(relations)
    relations.map{|r| r.presentation}
  end

  # Converts a list of relations to a list of presentations from the relation.related presentation
  def self.target(relations)
    relations.map{|r| r.related}
  end

  # Finds the relations for presentations about the specified presentation. The controller needs the relation ID to
  # delete it - but the view needs the .presentation objects. 
  def self.targeting(presentation, relationship_type)
    Relation.where("kind = ? AND related_id = ?", relationship_type ,presentation.id).includes(:presentation, :related)
  end

  # Finds the relations for that the specified presentation is about. The controller needs the relation ID to
  # delete it - but the view needs the .related presentation objects. 
  def self.sourcing(presentation, relationship_type)
    Relation.where("kind = ? AND presentation_id = ?", relationship_type, presentation.id).includes(:presentation, :related)
  end
end
