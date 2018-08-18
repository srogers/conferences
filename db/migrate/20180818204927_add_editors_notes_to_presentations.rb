class AddEditorsNotesToPresentations < ActiveRecord::Migration[5.2]
  def change
    add_column "presentations", :editors_notes, :text
  end
end
