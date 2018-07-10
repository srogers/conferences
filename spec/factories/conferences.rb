FactoryBot.define do
  factory :conference do
    start_date    '2005/07/15'.to_date
    end_date      '2005/07/23'.to_date
    organizer_id  1
  end
end
