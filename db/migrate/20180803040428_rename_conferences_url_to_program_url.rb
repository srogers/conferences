class RenameConferencesUrlToProgramUrl < ActiveRecord::Migration[5.2]
  def change
    # because this conflicts with having a #url method for the URL of the conference in the system.
    rename_column "conferences", :url, :program_url
  end
end
