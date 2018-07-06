class AddShowAttendanceToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column "users", :show_attendance, :boolean, default: true
  end
end
