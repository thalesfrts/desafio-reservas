require "rails_helper"

RSpec.describe "Tickets", type: :request do
  describe "POST /tickets" do
    it "allows resident to create ticket for linked unit" do
      resident = create(:user, :resident)
      unit = create(:unit)
      create(:user_unit, user: resident, unit: unit)
      ticket_type = create(:ticket_type)
      default_status = create(:ticket_status, :opened_default)

      sign_in resident

      expect do
        post tickets_path, params: {
          ticket: {
            unit_id: unit.id,
            ticket_type_id: ticket_type.id,
            description: "Vazamento no banheiro"
          }
        }
      end.to change(Ticket, :count).by(1)

      created = Ticket.order(:id).last
      expect(created.user).to eq(resident)
      expect(created.unit).to eq(unit)
      expect(created.ticket_status).to eq(default_status)
      expect(response).to redirect_to(ticket_path(created))
    end

    it "does not allow resident to create ticket for unrelated unit" do
      resident = create(:user, :resident)
      linked_unit = create(:unit)
      foreign_unit = create(:unit)
      create(:user_unit, user: resident, unit: linked_unit)
      ticket_type = create(:ticket_type)
      create(:ticket_status, :opened_default)

      sign_in resident

      expect do
        post tickets_path, params: {
          ticket: {
            unit_id: foreign_unit.id,
            ticket_type_id: ticket_type.id,
            description: "Teste"
          }
        }
      end.not_to change(Ticket, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /tickets/:id" do
    it "allows collaborator to view ticket inside assigned scope" do
      collaborator = create(:user, :collaborator)
      assigned_type = create(:ticket_type)
      create(:user_ticket_type, user: collaborator, ticket_type: assigned_type)
      ticket = create(:ticket, ticket_type: assigned_type)

      sign_in collaborator
      get ticket_path(ticket)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /tickets/:id" do
    it "does not let resident change ticket status" do
      resident = create(:user, :resident)
      unit = create(:unit)
      create(:user_unit, user: resident, unit: unit)

      from_status = create(:ticket_status, :in_progress)
      to_status = create(:ticket_status, :concluded_final)
      ticket = create(:ticket, user: resident, unit: unit, ticket_status: from_status)

      sign_in resident
      patch ticket_path(ticket), params: {
        ticket: {
          ticket_status_id: to_status.id,
          closing_note: "Finalizado"
        }
      }

      expect(response).to redirect_to(tickets_path)
      expect(ticket.reload.ticket_status).to eq(from_status)
      expect(ticket.resolved_at).to be_nil
    end

    it "allows collaborator to move the ticket to a custom intermediate status" do
      collaborator = create(:user, :collaborator)
      ticket_type = create(:ticket_type)
      create(:user_ticket_type, user: collaborator, ticket_type: ticket_type)

      opened = create(:ticket_status, :opened_default)
      custom_status = create(:ticket_status, name: "Aguardando material", is_default: false, is_final: false)
      ticket = create(:ticket, ticket_type: ticket_type, ticket_status: opened)

      sign_in collaborator
      patch ticket_path(ticket), params: {
        ticket: {
          ticket_status_id: custom_status.id
        }
      }

      expect(response).to redirect_to(ticket_path(ticket))
      expect(ticket.reload.ticket_status).to eq(custom_status)
    end
  end
end
