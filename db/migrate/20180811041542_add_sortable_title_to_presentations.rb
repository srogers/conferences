class AddSortableTitleToPresentations < ActiveRecord::Migration[5.2]
  def up
    add_column "presentations", :sortable_name, :string
    Presentation.find_each do |presentation|
      presentation.save # touch each one to generate the new sortable name
    end
  end

  def down
    remove_column "presentations", :sortable_name
  end
end
