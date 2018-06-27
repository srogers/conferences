class CreatePresentations < ActiveRecord::Migration[5.2]
  def change
    create_table :presentations do |t|
      t.string :name
      t.text   :description
      t.boolean :tape
      t.boolean :cd
      t.boolean :vhs
      t.string :estore_url
      t.string :video_url

      t.belongs_to  :speaker
      t.belongs_to  :conference
      t.belongs_to  :creator

      t.timestamps
    end
  end
end
