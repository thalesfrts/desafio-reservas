require "rails_helper"

RSpec.describe "Ticket status flow", type: :request do
  describe "PATCH /tickets/:id" do
    it "allows admin to reopen concluded ticket" do
      admin = create(:user, :administrator)
      concluded = create(:ticket_status, :concluded_final)
      reopened = create(:ticket_status, :reopened)
      ticket = create(:ticket, ticket_status: concluded, resolved_at: 1.hour.ago)

      sign_in admin

      patch ticket_path(ticket), params: {
        ticket: {
          ticket_status_id: reopened.id,
          reopen_reason: "Necessita nova visita"
        }
      }

      expect(response).to redirect_to(ticket_path(ticket))
      expect(ticket.reload.ticket_status).to eq(reopened)
      expect(ticket.resolved_at).to be_nil
    end

    it "does not allow collaborator to reopen concluded ticket" do
      collaborator = create(:user, :collaborator)
      ticket_type = create(:ticket_type)
      create(:user_ticket_type, user: collaborator, ticket_type: ticket_type)

      concluded = create(:ticket_status, :concluded_final)
      reopened = create(:ticket_status, :reopened)
      ticket = create(:ticket, ticket_type: ticket_type, ticket_status: concluded, resolved_at: 1.hour.ago)

      sign_in collaborator

      patch ticket_path(ticket), params: {
        ticket: {
          ticket_status_id: reopened.id,
          reopen_reason: "Tentativa sem permissão"
        }
      }

      expect(response).to redirect_to(ticket_path(ticket))
      expect(ticket.reload.ticket_status).to eq(concluded)
      expect(ticket.resolved_at).to be_present
    end

    it "fills resolved_at when ticket is concluded" do
      collaborator = create(:user, :collaborator)
      ticket_type = create(:ticket_type)
      create(:user_ticket_type, user: collaborator, ticket_type: ticket_type)

      in_progress = create(:ticket_status, :in_progress)
      concluded = create(:ticket_status, :concluded_final)
      ticket = create(:ticket, ticket_type: ticket_type, ticket_status: in_progress, resolved_at: nil)

      sign_in collaborator

      patch ticket_path(ticket), params: {
        ticket: {
          ticket_status_id: concluded.id,
          closing_note: "Atendimento concluído"
        }
      }

      expect(response).to redirect_to(ticket_path(ticket))
      expect(ticket.reload.ticket_status).to eq(concluded)
      expect(ticket.resolved_at).to be_present
    end

    it "sets resolved_at back to nil when ticket is reopened by admin" do
      admin = create(:user, :administrator)
      concluded = create(:ticket_status, :concluded_final)
      reopened = create(:ticket_status, :reopened)
      ticket = create(:ticket, ticket_status: concluded, resolved_at: Time.current)

      sign_in admin

      patch ticket_path(ticket), params: {
        ticket: {
          ticket_status_id: reopened.id,
          reopen_reason: "Reabertura para novo reparo"
        }
      }

      expect(response).to redirect_to(ticket_path(ticket))
      expect(ticket.reload.ticket_status).to eq(reopened)
      expect(ticket.resolved_at).to be_nil
    end

    it "allows admin to move an opened ticket directly to a custom final status" do
      admin = create(:user, :administrator)
      opened = create(:ticket_status, :opened_default)
      final_status = create(:ticket_status, name: "Encerrado", is_default: false, is_final: true)
      ticket = create(:ticket, ticket_status: opened, resolved_at: nil)

      sign_in admin

      patch ticket_path(ticket), params: {
        ticket: {
          ticket_status_id: final_status.id,
          closing_note: "Encerramento administrativo"
        }
      }

      expect(response).to redirect_to(ticket_path(ticket))
      expect(ticket.reload.ticket_status).to eq(final_status)
      expect(ticket.resolved_at).to be_present
    end
  end
end
