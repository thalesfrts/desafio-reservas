class AuditLog < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_actor, ->(actor_id) { where(actor_id: actor_id) if actor_id.present? }
  scope :by_action, ->(action) { where(action: action) if action.present? }
  scope :by_auditable_type, ->(auditable_type) { where(auditable_type: auditable_type) if auditable_type.present? }

  scope :from_date, ->(date) { where("audit_logs.created_at >= ?", date.beginning_of_day) if date.present? }
  scope :to_date, ->(date) { where("audit_logs.created_at <= ?", date.end_of_day) if date.present? }

  scope :search_text, lambda { |query|
    next if query.blank?

    q = "%#{query.strip}%"

    left_outer_joins(:actor).where(
      "audit_logs.action ILIKE :q OR audit_logs.auditable_type ILIKE :q OR CAST(audit_logs.auditable_id AS TEXT) ILIKE :q OR users.name ILIKE :q OR users.email ILIKE :q OR CAST(audit_logs.context_data AS TEXT) ILIKE :q",
      q: q
    )
  }
end
