class MoveDurationToPublications < ActiveRecord::Migration[5.2]
  # there's no data migration with this, because there isn't a 1:1 mapping
  def change
    add_column    "publications",  :duration, :integer
    remove_column "presentations", :duration, :integer
  end
end
