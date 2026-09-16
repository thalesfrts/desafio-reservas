FactoryBot.define do
  factory :ticket_status do
    sequence(:name) { |n| "Status #{n}" }
    is_default { false }
    is_final { false }

    initialize_with { TicketStatus.find_or_initialize_by(name: name) }

    to_create do |status|
      if status.is_default?
        TicketStatus.where.not(id: status.id).update_all(is_default: false)
      end

      status.save!
    end

    trait :opened_default do
      name { "Aberto" }
      is_default { true }
      is_final { false }
    end

    trait :in_progress do
      name { "Em andamento" }
      is_default { false }
      is_final { false }
    end

    trait :concluded_final do
      name { "Concluido" }
      is_default { false }
      is_final { true }
    end

    trait :reopened do
      name { "Reaberto" }
      is_default { false }
      is_final { false }
    end
  end
end
