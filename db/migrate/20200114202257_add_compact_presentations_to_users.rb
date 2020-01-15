class AddCompactPresentationsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column "users", :compact_presentations, :boolean, default: false
  end
end
