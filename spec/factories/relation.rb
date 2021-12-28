FactoryBot.define do
  factory :relation do
    association :presentation 
    association :related, factory: :presentation
    kind  { Relation::ABOUT }
  end
end
