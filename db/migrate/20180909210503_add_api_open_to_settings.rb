class AddApiOpenToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column "settings", :api_open, :boolean
  end
end
