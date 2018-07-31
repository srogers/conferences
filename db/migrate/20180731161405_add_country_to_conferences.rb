class AddCountryToConferences < ActiveRecord::Migration[5.2]
  def change
    add_column "conferences", :country, :string
  end
end
