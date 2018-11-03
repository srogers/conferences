class CreateUserPresentations < ActiveRecord::Migration[5.2]
  def change
    create_table :user_presentations do |t|
      t.belongs_to  :user
      t.belongs_to  :presentation

      t.date        :completed_on
      t.boolean     :notify_pubs
      t.text        :notes

      t.timestamps
    end
  end
end
