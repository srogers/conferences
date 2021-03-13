class AddClosedBetaToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column "settings", :closed_beta, :boolean, default: false
  end
end
