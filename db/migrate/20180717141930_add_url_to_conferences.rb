class AddUrlToConferences < ActiveRecord::Migration[5.2]
  def change
    add_column "conferences", :url, :string
  end
end
