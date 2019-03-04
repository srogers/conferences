class AddSortableNameToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column "users", :sortable_name, :string
    User.find_each do |user|
      user.save # touch each one to generate the new sortable name
    end

    add_index "users", :sortable_name unless index_exists? "users", :sortable_name
  end

  def down
    remove_column "users", :sortable_name
  end
end
