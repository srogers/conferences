class CreatePublications < ActiveRecord::Migration[5.2]
  def up
    remove_column "presentations", :tape
    remove_column "presentations", :cd
    remove_column "presentations", :vhs
    remove_column "presentations", :estore_url
    remove_column "presentations", :video_url

    create_table :publications do |t|
      t.belongs_to :presentation
      t.belongs_to :creator

      t.date       :published_on
      t.string     :format
      t.string     :url

      t.timestamps
    end
  end

  def down
    remove_table :publications

    add_column "presentations", :tape, :boolean
    add_column "presentations", :cd, :boolean
    add_column "presentations", :vhs, :boolean
    add_column "presentations", :estore_url, :string
    add_column "presentations", :video_url, :string
  end
end
