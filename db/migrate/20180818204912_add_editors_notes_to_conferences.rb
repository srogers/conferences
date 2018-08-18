class AddEditorsNotesToConferences < ActiveRecord::Migration[5.2]
  def change
    add_column "conferences", :editors_notes, :text
  end
end
