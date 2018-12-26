class RemovePresentationIdFromPublications < ActiveRecord::Migration[5.2]
  def change
    remove_column "publications", :presentation_id, :integer
  end
end
