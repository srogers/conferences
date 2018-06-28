class AddSortableNameToSpeakers < ActiveRecord::Migration[5.2]
  def up
    add_column "speakers", :sortable_name, :string
    Speaker.find_each do |speaker|
      speaker.update_attribute :sortable_name, speaker.name.split(' ').last
    end
  end

  def down
    remove_column "speakers", :sortable_name
  end
end
