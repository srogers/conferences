class CreateOrganizers < ActiveRecord::Migration[5.2]
  def change
    create_table :organizers do |t|
      t.string :name
      t.string :series_name
      t.string :abbreviation

      t.timestamps
    end
  end
end
