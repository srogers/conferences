class AddSpeakerNamesToPublication < ActiveRecord::Migration[5.2]
  def change
    add_column "publications", :speaker_names, :string
  end
end
