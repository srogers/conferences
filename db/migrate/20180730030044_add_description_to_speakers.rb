class AddDescriptionToSpeakers < ActiveRecord::Migration[5.2]
  def change
    add_column "speakers", :description, :text
  end
end
