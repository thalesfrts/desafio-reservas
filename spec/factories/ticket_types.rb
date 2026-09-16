FactoryBot.define do
  factory :ticket_type do
    sequence(:title) { |n| "Tipo #{n}" }
    sla_hours { 24 }
  end
end
