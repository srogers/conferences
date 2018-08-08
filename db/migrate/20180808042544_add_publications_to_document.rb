class AddPublicationsToDocument < ActiveRecord::Migration[5.2]
  def change
    add_column "documents", :publications, :boolean, default: false
  end
end
