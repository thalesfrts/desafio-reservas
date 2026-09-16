class TicketStatus < ApplicationRecord
  has_many :tickets, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :is_default, inclusion: { in: [ true, false ] }
  validates :is_final, inclusion: { in: [ true, false ] }

  validate :only_one_default, if: :is_default?
  validate :default_status_rules
  before_destroy :prevent_default_status_destroy

  private

  def only_one_default
    if TicketStatus.where(is_default: true).where.not(id: id).exists?
      errors.add(:is_default, "já existe um status padrão")
    end
  end

  def default_status_rules
    errors.add(:is_final, "não pode ser marcado para o status padrão") if is_default? && is_final?
  end

  def prevent_default_status_destroy
    return unless is_default?

    errors.add(:base, "O status padrão não pode ser excluído.")
    throw(:abort)
  end
end
