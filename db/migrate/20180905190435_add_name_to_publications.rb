class AddNameToPublications < ActiveRecord::Migration[5.2]
  def up
    # publications need a name distinct from the presentation
    add_column "publications", :name, :string

    # populate the table from the old relationship where publications belong to presentations
    execute "INSERT INTO presentation_publications (presentation_id, publication_id, creator_id, created_at, updated_at) SELECT pr.id, pu.id, pu.creator_id, pu.created_at, pu.updated_at  FROM presentations pr, publications pu WHERE pu.presentation_id = pr.id"

    # Initialize the name from the old belongs_to relationship - assume the ID is in the DB, but don't assume the relationship is still defined
    Publication.find_each do |publication|
      presentation = Presentation.find(publication.presentation_id) rescue false
      if presentation.present?
        publication.update_attribute :name, presentation.name
      else
        Rails.logger.warn "Couldn't find presentation ID #{ publication.presentation_id }"
      end
    end
  end

  def down
    remove_column "publications", :name
  end
end
