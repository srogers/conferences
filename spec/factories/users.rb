FactoryBot.define do
  factory :user, aliases: [:creator] do
    name                  "Testing User"
    sequence(:email)      { |n| "person#{n}@example.com" }
    password              "changeme1"
    password_confirmation "changeme1"
    active                true
    approved              true

    role                  { create :role }
  end

  factory :reader_user, :parent => :user do
    role    { create :role, name: Role::READER }
  end

  factory :editor_user, :parent => :user do
    role    { create :role, name: Role::EDITOR }
  end

  factory :admin_user, :parent => :user do
    role    { create :role, name: Role::ADMIN }
  end
end
