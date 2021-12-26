class CreateRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :relations do |t|
      t.belongs_to  :presentation
      t.references  :related, foreign_key: { to_table: :presentations }, index: true
      t.string      :kind
      t.string      :notes

      t.timestamps
    end
  end
end
