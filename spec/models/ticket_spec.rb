require "rails_helper"

RSpec.describe Ticket, type: :model do
  describe "status workflow" do
    it "applies default status on create when none is provided" do
      default_status = create(:ticket_status, :opened_default)
      ticket = build(:ticket, ticket_status: nil)

      expect(ticket.save).to be(true)
      expect(ticket.ticket_status).to eq(default_status)
    end

    it "rejects ticket creation for resident not linked to unit" do
      create(:ticket_status, :opened_default)
      resident = create(:user, :resident)
      foreign_unit = create(:unit)
      ticket = build(:ticket, user: resident, unit: foreign_unit, ticket_status: nil)

      expect(ticket).not_to be_valid
      expect(ticket.errors[:unit_id]).to include("não está vinculada ao morador")
    end

    it "requires administrator to reopen a concluded ticket" do
      concluded = create(:ticket_status, :concluded_final)
      reopened = create(:ticket_status, :reopened)
      ticket = create(:ticket, ticket_status: concluded)

      ticket.acting_user = create(:user, :collaborator)
      ticket.reopen_reason = "Revisar atendimento"

      expect(ticket.update(ticket_status: reopened)).to be(false)
      expect(ticket.errors[:base]).to include("Apenas administradores podem reabrir chamados concluídos.")
    end

    it "requires reopen reason when admin reopens a concluded ticket" do
      concluded = create(:ticket_status, :concluded_final)
      reopened = create(:ticket_status, :reopened)
      ticket = create(:ticket, ticket_status: concluded)

      ticket.acting_user = create(:user, :administrator)
      ticket.reopen_reason = ""

      expect(ticket.update(ticket_status: reopened)).to be(false)
      expect(ticket.errors[:reopen_reason]).to include("é obrigatório ao reabrir um chamado.")
    end

    it "requires closing note when concluding a ticket" do
      in_progress = create(:ticket_status, :in_progress)
      concluded = create(:ticket_status, :concluded_final)
      ticket = create(:ticket, ticket_status: in_progress)

      ticket.acting_user = create(:user, :collaborator)
      ticket.closing_note = ""

      expect(ticket.update(ticket_status: concluded)).to be(false)
      expect(ticket.errors[:closing_note]).to include("é obrigatório ao concluir um chamado.")
    end

    it "allows collaborator to move an opened ticket to a custom intermediate status" do
      opened = create(:ticket_status, :opened_default)
      custom_status = create(:ticket_status, name: "Aguardando material", is_default: false, is_final: false)
      ticket = create(:ticket, ticket_status: opened)

      ticket.acting_user = create(:user, :collaborator)

      expect(ticket.update(ticket_status: custom_status)).to be(true)
      expect(ticket.reload.ticket_status).to eq(custom_status)
    end

    it "includes custom intermediate and final statuses after work has started" do
      in_progress = create(:ticket_status, :in_progress)
      custom_status = create(:ticket_status, name: "Aguardando vistoria", is_default: false, is_final: false)
      final_status = create(:ticket_status, name: "Encerrado", is_default: false, is_final: true)
      ticket = create(:ticket, ticket_status: in_progress)

      allowed_statuses = ticket.allowed_next_statuses_for(create(:user, :collaborator))

      expect(allowed_statuses).to include(custom_status)
      expect(allowed_statuses).to include(final_status)
    end
  end
end
