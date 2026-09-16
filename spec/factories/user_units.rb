FactoryBot.define do
  factory :user_unit do
    association :user, :resident
    association :unit
  end
end
