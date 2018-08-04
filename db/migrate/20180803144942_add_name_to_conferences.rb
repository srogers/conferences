class AddNameToConferences < ActiveRecord::Migration[5.2]
  def change
    add_column "conferences", :name, :string
  end
end
