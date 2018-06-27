class CreateConferences < ActiveRecord::Migration[5.2]
  def change
    create_table :conferences do |t|
      t.date   :start_date
      t.date   :end_date
      t.string :venue
      t.string :venue_url
      t.string :city
      t.string :state

      t.belongs_to  :organizer
      t.belongs_to  :creator

      t.timestamps
    end
  end
end
