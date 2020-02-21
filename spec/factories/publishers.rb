FactoryBot.define do
  factory :publisher do
    sequence(:name)      { |n| "Publisher Number #{n}" }
  end
end
