require "rails_helper"

RSpec.describe User, type: :model do
  it "does not allow demoting the last administrator" do
    User.where(role: :administrator).update_all(role: User.roles[:resident])
    admin = create(:user, :administrator)

    admin.role = :resident

    expect(admin).not_to be_valid
    expect(admin.errors[:role]).to include("não pode ser alterada: este é o último administrador do sistema")
  end

  it "allows demotion when another administrator exists" do
    User.where(role: :administrator).update_all(role: User.roles[:resident])
    create(:user, :administrator)
    admin = create(:user, :administrator)

    admin.role = :resident

    expect(admin).to be_valid
  end
end
