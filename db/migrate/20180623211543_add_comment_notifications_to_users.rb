class AddCommentNotificationsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column "users", :comment_notifications, :boolean, default: false
  end
end
