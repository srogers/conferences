class AddTitleToSpeakers < ActiveRecord::Migration[5.2]
  def change
    add_column :speakers, "title", :string
  end
end
