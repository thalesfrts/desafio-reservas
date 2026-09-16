FactoryBot.define do
  factory :block do
    sequence(:identification) { |n| "Bloco #{n}" }
    floors_count { 1 }
    apartments_per_floor { 1 }
  end
end
