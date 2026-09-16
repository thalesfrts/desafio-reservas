FactoryBot.define do
  factory :user_ticket_type do
    association :user, :collaborator
    association :ticket_type
  end
end
