class RemoveCommentNotificationsFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column "users", :comment_notifications, :boolean, default: false
  end
end
