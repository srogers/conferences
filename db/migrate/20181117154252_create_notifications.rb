class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.belongs_to  :user_presentation
      t.belongs_to  :presentation_publication

      t.date        :sent_at  # to mark the time and denote sent vs. unsent when Sidekiq is handling it
      t.boolean     :seen     # so the user can check-off an acknowledgment box

      t.timestamps
    end
  end
end
