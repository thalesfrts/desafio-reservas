class Unit < ApplicationRecord
  belongs_to :block
  has_many :user_units, dependent: :destroy
  has_many :users, through: :user_units

  validates :identifier, presence: true
end
