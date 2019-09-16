FactoryBot.define do
  factory :document do
    name         { "Some Name" }
    format       { Document::PDF }
    file_size    { 1024 }
    content_type { 'attachment/pdf' }
    status       { Document::PENDING }
    events  { true }                # the name gets set based on this from params

    association :creator, factory: :user
  end
end
