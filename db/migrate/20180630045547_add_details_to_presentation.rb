class AddDetailsToPresentation < ActiveRecord::Migration[5.2]
  def change
    add_column "presentations", :parts,    :integer  # the number of parts, for multi-part presentations
    add_column "presentations", :duration, :integer  # the total duration (for recorded material)
  end
end
