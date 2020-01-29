FactoryBot.define do
  factory :supplement do
    name            { 'The attachment' }
    description     { 'The conference program' }
    url             { 'http://www.archive.org/some_old_program' }

    association :conference, factory: :conference
    association :creator, factory: :user
  end
end
