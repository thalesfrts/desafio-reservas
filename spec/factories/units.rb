FactoryBot.define do
  factory :unit do
    association :block
    sequence(:identifier) { |n| "U#{n}" }
  end
end
