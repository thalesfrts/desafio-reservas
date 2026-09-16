FactoryBot.define do
  factory :audit_log do
    association :actor, factory: [ :user, :administrator ]
    action { "ticket.created" }
    auditable_type { "Ticket" }
    auditable_id { 1 }
    context_data { { "controller" => "tickets", "action_name" => "create" } }
    change_set { { "description" => { "from" => nil, "to" => "Exemplo" } } }
    ip_address { "127.0.0.1" }
    request_id { SecureRandom.uuid }
    user_agent { "RSpec" }
  end
end
