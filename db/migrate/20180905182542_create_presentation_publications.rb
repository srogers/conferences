class CreatePresentationPublications < ActiveRecord::Migration[5.2]
  def change
    create_table :presentation_publications do |t|
      t.belongs_to :presentation
      t.belongs_to :publication
      t.belongs_to :creator

      t.boolean    :canonical     # True when the publication is about this exact presentation - e.g., transcript, audio, or video of this exact talk, not just similar name

      t.timestamps
      t.index ['presentation_id', 'publication_id'], unique: true, name: 'index_presentation_publications_on_presentation_and_publication'
    end
  end
end
