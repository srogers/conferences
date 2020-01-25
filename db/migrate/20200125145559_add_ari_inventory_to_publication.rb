class AddAriInventoryToPublication < ActiveRecord::Migration[5.2]
  def change
    # This is just a boolean because it's either found or not.
    # There's no third unverified state - either we found it, or we haven't found it yet.
    add_column "publications", :ari_inventory, :boolean, :default => false, null: false
  end
end
