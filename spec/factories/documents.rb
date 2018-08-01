FactoryBot.define do
  factory :document do
    name         "Some Name"
    file_size    1024
    content_type 'attachment/pdf'

    association :creator, factory: :user
  end
end
