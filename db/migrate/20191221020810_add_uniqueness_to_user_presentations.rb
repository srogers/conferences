class AddUniquenessToUserPresentations < ActiveRecord::Migration[5.2]
  def change
    add_index :user_presentations, ["user_id", "presentation_id"], unique: true
  end
end
