class AddCompletedToConferences < ActiveRecord::Migration[5.2]
  def change
    add_column "conferences", :completed, :boolean, default: false
  end
end
