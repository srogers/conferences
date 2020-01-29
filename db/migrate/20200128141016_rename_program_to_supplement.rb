class RenameProgramToSupplement < ActiveRecord::Migration[5.2]
  def change
    rename_table "programs", "supplements"
  end
end
