class RemoveCompactPresentations < ActiveRecord::Migration[5.2]
  def change
    remove_column "users", :compact_presentations, :boolean, default: false
  end
end
