class AddBaseEventYearToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column "settings", :base_event_year, :integer
  end
end
