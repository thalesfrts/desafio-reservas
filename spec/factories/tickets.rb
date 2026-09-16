FactoryBot.define do
  factory :ticket do
    association :unit
    ticket_type
    association :ticket_status, :in_progress
    description { "Chamado de teste" }

    user do
      resident = create(:user, :resident)
      create(:user_unit, user: resident, unit: unit)
      resident
    end
  end
end
