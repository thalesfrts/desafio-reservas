class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :ticket, optional: true

  enum :kind, {
    comment_added: "comment_added",
    status_changed: "status_changed"
  }

  validates :kind, :title, :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def mark_as_read!
    return if read_at.present?

    update!(read_at: Time.current)
  end
end
