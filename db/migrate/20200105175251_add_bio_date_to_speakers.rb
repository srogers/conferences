class AddBioDateToSpeakers < ActiveRecord::Migration[5.2]
  def change
    add_column "speakers", :bio_on, :date
  end
end
