class CreateDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :documents do |t|
      t.string  :name           # fields set at create time
      t.integer :creator_id

      t.string  :format         # options passed to the generation process
      t.boolean :conferences
      t.boolean :presentations
      t.boolean :speakers

      t.string  :status         # fields that get set during the generation process
      t.string  :attachment
      t.string  :content_type
      t.string  :file_size

      t.timestamps
    end
  end
end
