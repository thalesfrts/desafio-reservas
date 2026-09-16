class UserUnit < ApplicationRecord
  belongs_to :user
  belongs_to :unit

  validates :unit_id, uniqueness: { scope: :user_id }
  validate :user_must_be_resident

  private

  def user_must_be_resident
    return if user.blank?
    return if user&.resident?

    errors.add(:user, "deve ser morador")
  end
end
