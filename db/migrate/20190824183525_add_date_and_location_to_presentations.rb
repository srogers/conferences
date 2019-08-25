class AddDateAndLocationToPresentations < ActiveRecord::Migration[5.2]
  def change
    add_column "presentations", :date, :date
    add_column "presentations", :venue, :string
    add_column "presentations", :venue_url, :string
    add_column "presentations", :city, :string
    add_column "presentations", :state, :string
    add_column "presentations", :country, :string
  end
end
