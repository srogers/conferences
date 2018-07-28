class AddHandoutToPresentations < ActiveRecord::Migration[5.2]
  def change
    add_column "presentations", :handout, :string
  end
end
