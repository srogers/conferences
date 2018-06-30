class RemoveSpeakerIdFromPresentations < ActiveRecord::Migration[5.2]
  def up
    remove_column "presentations", :speaker_id
  end

  def down
    add_column "presentations", :speaker_id, :integer
  end
end
