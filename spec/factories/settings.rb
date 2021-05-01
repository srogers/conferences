FactoryBot.define do
  factory :setting do
    require_account_approval  { false }
    disable_signups           { false }
    closed_beta               { false }
  end
end
