FactoryBot.define do
  factory :publication do
    name            { 'Some Publication' }
    format          { Publication::CD }
  end
end
