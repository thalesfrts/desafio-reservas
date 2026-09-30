class Area < ApplicationRecord
  # RN-01-01: Área não deve apagar reservas existentes se for alterada/retirada
  has_many :reservations, dependent: :restrict_with_error

  # Registro de auditoria usando a estrutura polimórfica herdada
  has_many :audit_logs, as: :auditable, dependent: :destroy

  validates :name, presence: true
end
