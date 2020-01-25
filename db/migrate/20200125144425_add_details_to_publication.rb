class AddDetailsToPublication < ActiveRecord::Migration[5.2]
  def change
    add_column "publications", :details, :string
  end
end
