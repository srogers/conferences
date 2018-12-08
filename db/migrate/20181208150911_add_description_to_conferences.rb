class AddDescriptionToConferences < ActiveRecord::Migration[5.2]
  def change
    add_column "conferences", :description, :text
  end
end
