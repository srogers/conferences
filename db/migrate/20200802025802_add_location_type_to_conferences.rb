class AddLocationTypeToConferences < ActiveRecord::Migration[5.2]
  def up
    add_column "conferences", :location_type, :string, default: Locations::PHYSICAL, null: false
    add_column "presentations", :location_type, :string, default: Locations::PHYSICAL, null: false

    execute("UPDATE conferences SET location_type = venue WHERE venue in ('Virtual', 'Multiple')")
    execute("UPDATE presentations SET location_type = venue WHERE venue in ('Virtual', 'Multiple')")
    # TODO - unspecified for blank?
  end

  def down
    remove_column "conferences", :location_type
    remove_column "presentations", :location_type
  end
end
