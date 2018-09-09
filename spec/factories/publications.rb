FactoryBot.define do
  factory :publication do
    name            { 'Some Publication' }
    speaker_names   { 'Somebbody' }
    format          { Publication::CD }
  end
end
