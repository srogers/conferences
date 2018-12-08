class AddDescriptionToOrganizers < ActiveRecord::Migration[5.2]
  def change
    add_column "organizers", :description, :text
  end
end
