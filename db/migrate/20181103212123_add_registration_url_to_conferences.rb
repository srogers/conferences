class AddRegistrationUrlToConferences < ActiveRecord::Migration[5.2]
  def change
    add_column :conferences, "registration_url", :string
  end
end
