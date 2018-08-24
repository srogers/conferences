class AddSpeakerIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column "users", :speaker_id, :integer
  end
end
