class AddIndexesToPassages < ActiveRecord::Migration[5.2]
  def change
    add_index :passages, :name, unique: true
    add_index :passages, [:view, :assign_var], unique: true
  end
end
