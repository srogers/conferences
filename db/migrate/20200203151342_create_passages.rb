class CreatePassages < ActiveRecord::Migration[5.2]
  def change
    create_table :passages do |t|
      t.references  :creator, foreign_key: { to_table: :users }, index: true
      t.string      :name             # human descriptive name
      t.string      :assign_var       # the controller will assign the text to an instance variable with this name
      t.string      :view             # the controller fetches all the content for a view using this as a handle
      t.text        :content
      t.boolean     :retain_versions, default: false  # retaining old versions is optional
      t.integer     :minor_version
      t.integer     :major_version

      t.timestamps
    end

    # This is automatically created, so the referenced user must exist
    # add_foreign_key :passages, :users, column: :creator_id, primary_key: "id"
  end
end
