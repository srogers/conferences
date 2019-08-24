class AddEventTypeToConferences < ActiveRecord::Migration[5.2]
  def change
    add_column "conferences", :event_type, :string
  end
end
