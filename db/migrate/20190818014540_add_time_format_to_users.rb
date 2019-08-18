class AddTimeFormatToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column "users", :time_format, :string, default: Publication::HMS
  end
end
