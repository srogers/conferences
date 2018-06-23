class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :crypted_password
      t.string :password_salt
      t.string :persistence_token

      # Authlogic::ActsAsAuthentic::PerishableToken
      t.string    :perishable_token

      # Authlogic::Session::MagicColumns
      t.integer   :login_count, default: 0, null: false
      t.integer   :failed_login_count, default: 0, null: false
      t.datetime  :last_request_at
      t.datetime  :current_login_at
      t.datetime  :last_login_at
      t.string    :current_login_ip
      t.string    :last_login_ip

      # Authlogic::Session::MagicStates
      t.boolean   :active,   default: false
      t.boolean   :approved, default: false

      t.string    :name
      t.string    :city
      t.string    :state
      t.string    :country
      t.string    :time_zone

      t.string    :photo

      t.timestamps
    end
  end
end
