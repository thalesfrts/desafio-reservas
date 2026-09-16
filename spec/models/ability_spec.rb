require "rails_helper"

RSpec.describe Ability, type: :model do
  describe "resident permissions" do
    it "allows reading tickets from linked unit and blocks others" do
      resident = create(:user, :resident)
      resident_unit = create(:unit)
      create(:user_unit, user: resident, unit: resident_unit)

      own_ticket = create(:ticket, user: resident, unit: resident_unit)

      other_resident = create(:user, :resident)
      other_unit = create(:unit)
      create(:user_unit, user: other_resident, unit: other_unit)
      foreign_ticket = create(:ticket, user: other_resident, unit: other_unit)

      ability = Ability.new(resident)

      expect(ability.can?(:read, own_ticket)).to be(true)
      expect(ability.can?(:read, foreign_ticket)).to be(false)
    end
  end

  describe "collaborator permissions" do
    it "allows updating tickets from assigned types and blocks others" do
      collaborator = create(:user, :collaborator)
      assigned_type = create(:ticket_type)
      create(:user_ticket_type, user: collaborator, ticket_type: assigned_type)

      resident = create(:user, :resident)
      unit = create(:unit)
      create(:user_unit, user: resident, unit: unit)

      allowed_ticket = create(:ticket, user: resident, unit: unit, ticket_type: assigned_type)
      blocked_ticket = create(:ticket, user: resident, unit: unit, ticket_type: create(:ticket_type))

      ability = Ability.new(collaborator)

      expect(ability.can?(:update, allowed_ticket)).to be(true)
      expect(ability.can?(:update, blocked_ticket)).to be(false)
    end
  end

  describe "administrator permissions" do
    it "allows full management" do
      admin = create(:user, :administrator)
      ticket = create(:ticket)

      ability = Ability.new(admin)

      expect(ability.can?(:manage, ticket)).to be(true)
    end
  end
end
