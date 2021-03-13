class AddDisableSignupsToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column "settings", :disable_signups, :boolean, default: false
  end
end
