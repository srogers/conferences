class ChangeConferenceSpeakersToPresentationSpeakers < ActiveRecord::Migration[5.2]
  def up
    drop_table :conference_speakers

    create_table :presentation_speakers do |t|
      t.belongs_to :presentation
      t.belongs_to :speaker
      t.belongs_to :creator

      t.timestamps
      t.index ['presentation_id', 'speaker_id'], unique: true
    end
  end

  def down
    drop_table :presentation_speakers

    create_table :conference_speakers do |t|
      t.belongs_to :conference
      t.belongs_to :speaker
      t.belongs_to :creator

      t.timestamps
      t.index ['conference_id', 'speaker_id'], unique: true
    end
  end
end
