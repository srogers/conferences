class AddPublisherToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column "publications", :publisher, :string
  end
end
