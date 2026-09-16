require "rails_helper"

RSpec.describe TicketStatus, type: :model do
  it "allows only one default status" do
    create(:ticket_status, :opened_default)
    duplicate_default = build(:ticket_status, name: "Outro padrão", is_default: true)

    expect(duplicate_default).not_to be_valid
    expect(duplicate_default.errors[:is_default]).to include("já existe um status padrão")
  end

  it "does not allow the default status to be final" do
    status = build(:ticket_status, name: "Aberto", is_default: true, is_final: true)

    expect(status).not_to be_valid
    expect(status.errors[:is_final]).to include("não pode ser marcado para o status padrão")
  end

  it "allows the default status name to be edited" do
    status = build(:ticket_status, name: "Em andamento", is_default: true, is_final: false)

    expect(status).to be_valid
  end

  it "does not destroy the default status" do
    status = create(:ticket_status, :opened_default)

    expect(status.destroy).to be(false)
    expect(status.errors[:base]).to include("O status padrão não pode ser excluído.")
    expect(TicketStatus.exists?(status.id)).to be(true)
  end
end
