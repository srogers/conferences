class CreateConferenceSpeakers < ActiveRecord::Migration[5.2]
  def change
    create_table :conference_speakers do |t|
      t.belongs_to :conference
      t.belongs_to :speaker
      t.belongs_to :creator

      t.timestamps
      t.index ['conference_id', 'speaker_id'], unique: true
    end
  end
end
