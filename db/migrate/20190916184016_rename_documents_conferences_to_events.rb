class RenameDocumentsConferencesToEvents < ActiveRecord::Migration[5.2]
  def change
    rename_column "documents", :conferences, :events
  end
end
