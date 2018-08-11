class AddBioUrlToSpeakers < ActiveRecord::Migration[5.2]
  def change
    add_column "speakers", :bio_url, :string
  end
end
