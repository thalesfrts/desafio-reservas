class Block < ApplicationRecord
  has_many :units, dependent: :destroy

  validates :identification, :floors_count, :apartments_per_floor, presence: true
  validates :floors_count, :apartments_per_floor, numericality: { greater_than: 0 }

  after_create :generate_units

  private

  def generate_units
    (1..floors_count).each do |floor|
      (1..apartments_per_floor).each do |apt|
        apt_two_digits = apt.to_s.rjust(2, "0")
        unit_number = "#{floor}#{apt_two_digits}"

        units.create!(identifier: unit_number)
      end
    end
  end
end
