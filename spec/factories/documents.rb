FactoryBot.define do
  factory :document do
    format       { Document::PDF }
    file_size    { 1024 }
    content_type { 'attachment/pdf' }
    events  { true }                # the name gets set based on this from params
    # status will automatically be set to Document::PENDING - spec has to set it directly separately

    association :creator, factory: :user
  end
end
