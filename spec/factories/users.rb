FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "123456" }
    password_confirmation { "123456" }
    role { :resident }

    trait :resident do
      role { :resident }
    end

    trait :collaborator do
      role { :collaborator }
    end

    trait :administrator do
      role { :administrator }
    end
  end
end
