class CreateSettings < ActiveRecord::Migration[5.0]
  def up
    create_table :settings do |t|
      t.boolean :require_account_approval, default: true
    end
    Setting.create   # make the first one - in any new system, this is handled by db:seeds
  end

  def down
    drop_table :settings
  end
end
