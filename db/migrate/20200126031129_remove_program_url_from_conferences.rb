class RemoveProgramUrlFromConferences < ActiveRecord::Migration[5.2]
  def change
    remove_column "conferences", :program_url, :string
  end
end
