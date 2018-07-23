class AddShowContributorToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column "users", :show_contributor, :boolean, default: true
  end
end
