class AddLanguageToPublication < ActiveRecord::Migration[5.2]
  def change
    add_reference :publications, :language, foreign_key: true
  end
end
