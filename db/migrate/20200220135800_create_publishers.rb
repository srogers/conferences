class CreatePublishers < ActiveRecord::Migration[5.2]
  # In the first iteration, publishers just stand along side media. The names just serve to mostly standardize
  # publishers, but relation is not by ID - publishers can be anything.
  def up
    create_table "publishers" do |t|
      t.belongs_to  :creator
      t.string      :name
      t.string      :description

      t.timestamps
      t.index ['name'], unique: true
    end

    # Bootstrap the table with the existing publishers
    execute "INSERT INTO publishers (name, created_at, updated_at) SELECT DISTINCT publisher, current_timestamp, current_timestamp  FROM publications WHERE publisher IS NOT NULL"
  end

  def down
    drop_table "publishers"
  end
end
