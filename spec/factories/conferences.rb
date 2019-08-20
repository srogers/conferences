FactoryBot.define do
  factory :conference do
    name          { 'The Testing Conference' }   # specifying this keeps it from being generated from Organizer - which wouldn't work unless we create one here
    event_type    { Conference::CONFERENCE }
    start_date    { '2005/07/15'.to_date }
    end_date      { '2005/07/23'.to_date }
    organizer_id  { 1 }
  end
end
