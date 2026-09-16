require "rails_helper"

RSpec.describe UserUnit, type: :model do
  it "accepts resident users" do
    user_unit = build(:user_unit)

    expect(user_unit).to be_valid
  end

  it "rejects non-resident users" do
    user_unit = build(:user_unit, user: create(:user, :collaborator))

    expect(user_unit).not_to be_valid
    expect(user_unit.errors[:user]).to include("deve ser morador")
  end
end
