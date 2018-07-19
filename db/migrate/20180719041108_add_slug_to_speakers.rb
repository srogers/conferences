class AddSlugToSpeakers < ActiveRecord::Migration[5.2]
  def change
    add_column "speakers", :slug, :string
  end
end
