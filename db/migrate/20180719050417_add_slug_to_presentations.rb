class AddSlugToPresentations < ActiveRecord::Migration[5.2]
  def change
    add_column "presentations", :slug, :string
  end
end
