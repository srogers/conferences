FactoryBot.define do
  factory :publication do
    name            { 'Some Publication' }
    speaker_names   { 'Somebody' }
    format          { Publication::CD }

    association :language, factory: :language
  end
end
