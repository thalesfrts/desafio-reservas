class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :area

  # Habilita o rastreio de auditoria nesta tabela
  has_many :audit_logs, as: :auditable, dependent: :destroy

  # RN-01-04 e RN-01-13: Estados do fluxo da reserva
  enum status: { requested: 0, approved: 1, denied: 2, canceled: 3 }

  validates :start_time, :end_time, presence: true

  # RN-01-08: A negação exige um motivo não vazio
  validates :denial_reason, presence: true, if: :denied?

  validate :end_time_after_start_time
  validate :start_time_in_future, on: :create
  validate :no_conflicting_approved_reservations, if: :approved?

  private

  # RN-01-02: O horário de fim deve ser posterior ao de início
  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "deve ser posterior ao horário de início")
    end
  end

  # RN-01-02: O início não pode estar no passado. Usamos Time.current como referência consistente (RNF-02).
  def start_time_in_future
    return if start_time.blank?

    if start_time <= Time.current
      errors.add(:start_time, "deve ser uma data e horário no futuro")
    end
  end

  # RN-01-05 e RN-01-07: Conflito de intervalos. Bloqueia se já houver reserva aprovada que se sobreponha.
  def no_conflicting_approved_reservations
    return if start_time.blank? || end_time.blank? || area_id.blank?

    conflicts = Reservation.where(area_id: area_id, status: :approved)
                           .where.not(id: id)
                           .where("start_time < ? AND end_time > ?", end_time, start_time)

    if conflicts.exists?
      errors.add(:base, "Já existe uma reserva aprovada para esta área neste horário")
    end
  end
end
