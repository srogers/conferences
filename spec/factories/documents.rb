FactoryBot.define do
  factory :document do
    name         { "Some Name" }
    format       { Document::PDF }
    file_size    { 1024 }
    content_type { 'attachment/pdf' }
    status       { Document::PENDING }
    conferences  { true }

    association :creator, factory: :user
  end
end
