class AddPrivacyPolicyVersionToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column "users", :privacy_policy_version, :string, default: "0.0"
  end
end
