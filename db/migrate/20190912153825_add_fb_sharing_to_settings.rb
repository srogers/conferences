class AddFbSharingToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column "settings", :facebook_sharing, :boolean
  end
end
