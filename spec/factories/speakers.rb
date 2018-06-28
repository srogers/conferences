FactoryBot.define do
  factory :speaker do
    sequence(:name)       { |n| "Testing Userperson#{n}" }
  end
end
