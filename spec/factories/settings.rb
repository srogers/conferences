FactoryBot.define do
  factory :setting do
    require_account_approval  { false }
    closed_beta               { false }
  end
end
