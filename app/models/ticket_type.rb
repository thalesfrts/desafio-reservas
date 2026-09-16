class TicketType < ApplicationRecord
    validates :title, presence: true, uniqueness: { case_sensitive: false }
    validates :sla_hours, presence: true, numericality: { only_integer: true, greater_than: 0 }

    has_many :tickets, dependent: :restrict_with_error
    has_many :user_ticket_types, dependent: :destroy
    has_many :collaborators, -> { where(role: :collaborator) }, through: :user_ticket_types, source: :user
end
