class UserTicketType < ApplicationRecord
  belongs_to :user
  belongs_to :ticket_type

  validates :ticket_type_id, uniqueness: { scope: :user_id, message: "Já está atribuído a este usuário" }
end
