class AddNotesToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column "publications", :notes, :string
  end
end
