class CreateConferenceUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :conference_users do |t|
      t.belongs_to :user
      t.belongs_to :conference
      t.belongs_to :creator

      t.timestamps
    end
  end
end
