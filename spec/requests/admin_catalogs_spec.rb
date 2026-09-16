require "rails_helper"

RSpec.describe "Admin catalogs", type: :request do
  describe "POST /ticket_types" do
    it "allows admin to create ticket type" do
      admin = create(:user, :administrator)
      sign_in admin

      expect do
        post ticket_types_path, params: {
          ticket_type: {
            title: "Elétrica",
            sla_hours: 12
          }
        }
      end.to change(TicketType, :count).by(1)

      expect(response).to redirect_to(ticket_types_path)
    end

    it "does not allow collaborator to create ticket type" do
      collaborator = create(:user, :collaborator)
      sign_in collaborator

      expect do
        post ticket_types_path, params: {
          ticket_type: {
            title: "Hidráulica",
            sla_hours: 24
          }
        }
      end.not_to change(TicketType, :count)

      expect(response).to redirect_to(tickets_path)
    end

    it "shows validation messages in pt-BR" do
      admin = create(:user, :administrator)
      sign_in admin

      post ticket_types_path, params: {
        ticket_type: {
          title: "",
          sla_hours: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Título não pode ficar em branco")
      expect(response.body).to include("Prazo (SLA em horas) não pode ficar em branco")
      expect(response.body).to include("Prazo (SLA em horas) não é um número")
      expect(response.body).not_to include("Title não pode")
      expect(response.body).not_to include("Sla hours")
    end
  end

  describe "DELETE /ticket_types/:id" do
    it "shows a friendly alert when the ticket type is linked to tickets" do
      admin = create(:user, :administrator)
      ticket_type = create(:ticket_type)
      create(:ticket, ticket_type: ticket_type)
      sign_in admin

      expect do
        delete ticket_type_path(ticket_type)
      end.not_to change(TicketType, :count)

      expect(response).to redirect_to(ticket_types_path)
      follow_redirect!
      expect(response.body).to include("Este tipo de chamado não pode ser excluído porque já está vinculado a um ou mais chamados.")
    end
  end

  describe "POST /ticket_statuses" do
    it "allows admin to create ticket status" do
      admin = create(:user, :administrator)
      sign_in admin

      expect do
        post ticket_statuses_path, params: {
          ticket_status: {
            name: "Aguardando material",
            is_default: false,
            is_final: false
          }
        }
      end.to change(TicketStatus, :count).by(1)

      expect(response).to redirect_to(ticket_statuses_path)
    end

    it "does not allow resident to create ticket status" do
      resident = create(:user, :resident)
      sign_in resident

      expect do
        post ticket_statuses_path, params: {
          ticket_status: {
            name: "Indevido",
            is_default: false,
            is_final: false
          }
        }
      end.not_to change(TicketStatus, :count)

      expect(response).to redirect_to(tickets_path)
    end

    it "shows validation messages in pt-BR" do
      admin = create(:user, :administrator)
      sign_in admin

      post ticket_statuses_path, params: {
        ticket_status: {
          name: "",
          is_default: false,
          is_final: false
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nome não pode ficar em branco")
      expect(response.body).not_to include("Name não pode")
    end
  end

  describe "DELETE /ticket_statuses/:id" do
    it "does not allow the default status to be deleted" do
      admin = create(:user, :administrator)
      default_status = create(:ticket_status, :opened_default)
      sign_in admin

      expect do
        delete ticket_status_path(default_status)
      end.not_to change(TicketStatus, :count)

      expect(response).to redirect_to(ticket_statuses_path)
      follow_redirect!
      expect(response.body).to include("Esse é um status padrão do sistema, não é permitido excluir. Você pode apenas editar o nome dele.")
    end
  end
end
