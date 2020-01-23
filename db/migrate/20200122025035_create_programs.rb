class CreatePrograms < ActiveRecord::Migration[5.2]
  def change
    create_table :programs do |t|
      t.belongs_to  :conference
      t.belongs_to  :creator

      t.string      :name
      t.string      :description
      t.string      :attachment
      t.string      :url
      t.string      :content_type
      t.string      :file_size
      t.string      :editors_notes

      t.timestamps
    end
  end
end
