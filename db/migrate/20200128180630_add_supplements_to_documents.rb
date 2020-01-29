class AddSupplementsToDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column "documents", :supplements, :boolean, default: false
  end
end
