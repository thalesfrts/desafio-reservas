class Ticket < ApplicationRecord
  SLA_AT_RISK_WINDOW = 4.hours
  MAX_ATTACHMENT_SIZE = 5.megabytes
  MAX_ATTACHMENTS = 1
  ALLOWED_ATTACHMENT_CONTENT_TYPES = %w[
    image/png
    image/jpeg
    image/webp
    image/gif
    image/heic
    image/heif
  ].freeze

  belongs_to :unit
  belongs_to :user
  belongs_to :ticket_type
  belongs_to :ticket_status

  has_many :comments, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many_attached :attachments

  attr_accessor :acting_user, :reopen_reason, :closing_note

  validates :description, presence: true
  validates :ticket_status, presence: true

  before_validation :set_default_status, on: :create
  before_validation :initialize_sla_cycle, on: :create
  before_validation :restart_sla_cycle_if_reopened, on: :update
  before_validation :sync_resolved_at_with_status
  before_save :sync_sla_breached_at

  validate :resident_unit_must_be_linked, on: :create
  validate :resolved_at_only_when_final
  validate :validate_reopen_conditions, on: :update
  validate :validate_closing_note_if_concluding, on: :update
  validate :validate_status_transition_rules, on: :update
  validate :validate_attachments

  after_update_commit :log_reopen_action, if: :transitioned_to_reopened?

  scope :with_sla, -> { where.not(sla_due_at: nil) }
  scope :sla_breached, ->(reference_time = Time.current) {
    with_sla.where(
      "(tickets.resolved_at IS NULL AND tickets.sla_due_at < :reference_time) OR " \
      "(tickets.resolved_at IS NOT NULL AND tickets.resolved_at > tickets.sla_due_at)",
      reference_time: reference_time
    )
  }
  scope :sla_at_risk, ->(reference_time = Time.current, window: SLA_AT_RISK_WINDOW) {
    threshold = reference_time + window
    with_sla.where(
      "tickets.resolved_at IS NULL AND tickets.sla_due_at >= :reference_time AND tickets.sla_due_at <= :threshold",
      reference_time: reference_time,
      threshold: threshold
    )
  }
  scope :sla_on_time, ->(reference_time = Time.current, window: SLA_AT_RISK_WINDOW) {
    threshold = reference_time + window
    with_sla.where(
      "(tickets.resolved_at IS NOT NULL AND tickets.resolved_at <= tickets.sla_due_at) OR " \
      "(tickets.resolved_at IS NULL AND tickets.sla_due_at > :threshold)",
      threshold: threshold
    )
  }

  def allowed_next_statuses_for(user, from_status: nil)
    status = from_status || ticket_status || TicketStatus.find_by(is_default: true)
    return [] if status.blank? || user.blank?

    if status.is_final?
      return user.administrator? ? reopened_statuses : []
    end

    available_statuses = if reopened_status?(status)
      workflow_statuses(excluding: status) + final_statuses
    elsif status.is_default?
      base_statuses = workflow_statuses(excluding: status)
      user.administrator? ? base_statuses + final_statuses : base_statuses
    else
      workflow_statuses(excluding: status) + final_statuses
    end

    available_statuses.uniq
  end

  def sla_status_key(reference_time = Time.current)
    return :no_sla if sla_due_at.blank?
    return :breached if sla_breached?(reference_time)
    return :on_time if ticket_status&.is_final?
    return :at_risk if reference_time >= (sla_due_at - SLA_AT_RISK_WINDOW)

    :on_time
  end

  def sla_breached?(reference_time = Time.current)
    return false if sla_due_at.blank?

    reference = resolved_at || reference_time
    reference > sla_due_at
  end

  def sla_delta_seconds(reference_time = Time.current)
    return nil if sla_due_at.blank?

    reference = resolved_at || reference_time
    (sla_due_at - reference).to_i
  end

  private

  def set_default_status
    self.ticket_status ||= TicketStatus.find_by(is_default: true)
  end

  def initialize_sla_cycle
    return if ticket_type.blank? || ticket_type.sla_hours.blank?

    started_at = sla_started_at || Time.current

    self.sla_cycle = 1 if sla_cycle.blank? || sla_cycle <= 0
    self.sla_started_at = started_at
    self.sla_due_at ||= calculate_sla_due_at(started_at)
  end

  def restart_sla_cycle_if_reopened
    return unless transitioning_to_reopened?
    return if ticket_type.blank? || ticket_type.sla_hours.blank?

    started_at = Time.current

    self.sla_cycle = (sla_cycle || 1) + 1
    self.sla_started_at = started_at
    self.sla_due_at = calculate_sla_due_at(started_at)
    self.sla_breached_at = nil
  end

  def resident_unit_must_be_linked
    return if user.blank? || unit_id.blank?
    return unless user.resident?

    unless user.units.exists?(id: unit_id)
      errors.add(:unit_id, "não está vinculada ao morador")
    end
  end

  def sync_resolved_at_with_status
    return unless will_save_change_to_ticket_status_id?

    if ticket_status&.is_final?
      self.resolved_at ||= Time.current
    else
      self.resolved_at = nil
    end
  end

  def sync_sla_breached_at
    return if sla_due_at.blank?

    if sla_breached?
      self.sla_breached_at ||= (resolved_at || Time.current)
    elsif resolved_at.present? && resolved_at <= sla_due_at
      self.sla_breached_at = nil
    end
  end

  def resolved_at_only_when_final
    return if resolved_at.blank?
    return if ticket_status&.is_final?
    errors.add(:resolved_at, "só pode existir quando o chamado estiver concluído")
  end

  def validate_reopen_conditions
    return unless transitioning_to_reopened?

    unless acting_user&.administrator?
      errors.add(:base, "Apenas administradores podem reabrir chamados concluídos.")
      return
    end

    if reopen_reason.to_s.strip.blank?
      errors.add(:reopen_reason, "é obrigatório ao reabrir um chamado.")
    end
  end

  def currently_concluding?
    return false unless ticket_status_id_changed?

    old_status_id, new_status_id = ticket_status_id_change
    old_status = TicketStatus.find_by(id: old_status_id)
    new_status = TicketStatus.find_by(id: new_status_id)

    !old_status&.is_final? && new_status&.is_final?
  end

  def validate_closing_note_if_concluding
    return unless currently_concluding?
    return unless closing_note.to_s.strip.blank?

    errors.add(:closing_note, "é obrigatório ao concluir um chamado.")
  end

  def validate_status_transition_rules
    return unless ticket_status_id_changed?

    old_status_id, new_status_id = ticket_status_id_change
    old_status = TicketStatus.find_by(id: old_status_id)
    new_status = TicketStatus.find_by(id: new_status_id)

    return if old_status_id == new_status_id

    allowed_status_ids = allowed_next_statuses_for(acting_user, from_status: old_status).map(&:id)

    unless allowed_status_ids.include?(new_status_id)
      errors.add(:ticket_status, "não permite a transição de #{status_label(old_status)} para #{status_label(new_status)}.")
    end
  end

  def transitioned_to_reopened?
    return false unless saved_change_to_ticket_status_id?

    old_status_id, new_status_id = saved_change_to_ticket_status_id
    old_status = TicketStatus.find_by(id: old_status_id)
    new_status = TicketStatus.find_by(id: new_status_id)

    old_status&.is_final? && normalized_status_name(new_status) == "reaberto"
  end

  def transitioning_to_reopened?
    return false unless ticket_status_id_changed?

    old_status_id, new_status_id = ticket_status_id_change
    old_status = TicketStatus.find_by(id: old_status_id)
    new_status = TicketStatus.find_by(id: new_status_id)

    old_status&.is_final? && normalized_status_name(new_status) == "reaberto"
  end

  def log_reopen_action
    comments.create!(
      user: acting_user || user,
      body: "Chamado reaberto automaticamente.\nMotivo informado: #{reopen_reason}"
    )
  end

  def calculate_sla_due_at(started_at)
    started_at + ticket_type.sla_hours.hours
  end

  def workflow_statuses(excluding: nil)
    TicketStatus.order(:name).reject do |status|
      status.id == excluding&.id || status.is_default? || status.is_final? || reopened_status?(status)
    end
  end

  def final_statuses
    TicketStatus.where(is_final: true).order(:name).to_a
  end

  def reopened_statuses
    TicketStatus.order(:name).select { |status| reopened_status?(status) }
  end

  def reopened_status?(status)
    normalized_status_name(status) == "reaberto"
  end

  def status_label(status)
    return "Sem status" if status.blank?

    status.name
  end

  def normalized_status_name(status)
    I18n.transliterate(status&.name.to_s).downcase.strip
  end

  def validate_attachments
    return unless attachments.attached?

    if attachments.count > MAX_ATTACHMENTS
      errors.add(:attachments, "permitem apenas 1 imagem por chamado")
    end

    attachments.each do |attachment|
      unless ALLOWED_ATTACHMENT_CONTENT_TYPES.include?(attachment.content_type)
        errors.add(:attachments, "devem conter apenas imagens (PNG, JPG, WEBP, GIF ou HEIC)")
      end

      if attachment.byte_size > MAX_ATTACHMENT_SIZE
        errors.add(:attachments, "#{attachment.filename} excede o limite de 5MB")
      end
    end
  end
end
