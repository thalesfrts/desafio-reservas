class User < ApplicationRecord
  has_many :user_units, dependent: :destroy
  has_many :units, through: :user_units
  has_many :user_ticket_types, dependent: :destroy
  has_many :assigned_ticket_types, through: :user_ticket_types, source: :ticket_type
  has_many :notifications, dependent: :destroy
  has_many :sent_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :nullify
  has_many :audit_logs, class_name: "AuditLog", foreign_key: :actor_id, dependent: :nullify

  devise :database_authenticatable, :rememberable, :validatable
  enum :role, { resident: 0, collaborator: 1, administrator: 2 }, default: :resident

  validates :name, presence: true
  validate :prevent_last_admin_demotion, on: :update

  private

  def prevent_last_admin_demotion
    return unless will_save_change_to_role?

    old_role_value, new_role_value = role_change_to_be_saved
    old_role = normalize_role_change_value(old_role_value)
    new_role = normalize_role_change_value(new_role_value)

    return unless old_role == "administrator" && new_role != "administrator"

    other_admin_exists = self.class.where(role: :administrator).where.not(id: id).exists?
    return if other_admin_exists

    errors.add(:role, "não pode ser alterada: este é o último administrador do sistema")
  end

  def normalize_role_change_value(value)
    return value if self.class.roles.key?(value)

    self.class.roles.key(value)
  end
end
