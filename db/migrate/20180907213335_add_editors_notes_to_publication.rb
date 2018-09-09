class AddEditorsNotesToPublication < ActiveRecord::Migration[5.2]
  def change
    add_column "publications", :editors_notes, :text
  end
end
