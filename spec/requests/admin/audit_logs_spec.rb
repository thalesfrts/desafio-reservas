require "rails_helper"

RSpec.describe "Admin::AuditLogs", type: :request do
  describe "GET /admin/audit_logs" do
    it "allows administrators to view and filter logs" do
      admin = create(:user, :administrator)
      create(:audit_log, actor: admin, action: "ticket.created")
      create(:audit_log, actor: admin, action: "ticket.updated")

      sign_in admin

      get admin_audit_logs_path, params: { audit_action: "ticket.created" }

      expect(response).to have_http_status(:ok)
      table_body = response.body[/<tbody[^>]*>(.*?)<\/tbody>/m, 1]

      expect(table_body).to include("Chamado criado")
      expect(table_body).not_to include("Chamado atualizado")
    end

    it "shows an alert when end date is before start date" do
      admin = create(:user, :administrator)
      create(:audit_log, actor: admin, action: "ticket.created")

      sign_in admin

      get admin_audit_logs_path, params: { from: "2026-04-15", to: "2026-04-10" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Não é possível filtrar uma data final antes da data inicial.")
      expect(response.body).to include("Chamado criado")
    end

    it "denies non-admin users" do
      collaborator = create(:user, :collaborator)

      sign_in collaborator
      get admin_audit_logs_path

      expect(response).to redirect_to(tickets_path)
    end
  end

  describe "GET /admin/audit_logs/:id" do
    it "shows details to administrators" do
      admin = create(:user, :administrator)
      log = create(:audit_log, actor: admin, action: "comment.created")

      sign_in admin
      get admin_audit_log_path(log)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Comentário criado")
    end

    it "renders simplified fields in pt-BR" do
      admin = create(:user, :administrator)
      status = create(:ticket_status, :opened_default)
      unit = create(:unit)
      log = create(
        :audit_log,
        actor: admin,
        action: "ticket.created",
        context_data: {
          ticket_id: 124,
          user_id: admin.id,
          description: "Teste de chamado"
        },
        change_set: {
          "user_id" => { "from" => nil, "to" => admin.id },
          "description" => { "from" => nil, "to" => "Teste de chamado" },
          "sla_due_at" => { "from" => nil, "to" => "2026-04-19T00:24:25-03:00" },
          "sla_started_at" => { "from" => nil, "to" => "2026-04-16T00:24:25-03:00" },
          "ticket_status_id" => { "from" => nil, "to" => status.id },
          "unit_id" => { "from" => nil, "to" => unit.id }
        }
      )

      sign_in admin
      get admin_audit_log_path(log)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Usuário")
      expect(response.body).to include("Descrição")
      expect(response.body).to include("Prazo do SLA")
      expect(response.body).to include("Início do SLA")
      expect(response.body).not_to include("User id")
      expect(response.body).not_to include("Description")
      expect(response.body).not_to include("Sla due at")
    end

    it "renders block fields in pt-BR" do
      admin = create(:user, :administrator)
      log = create(
        :audit_log,
        actor: admin,
        action: "block.created",
        change_set: {
          "identification" => { "from" => nil, "to" => "A" },
          "floors_count" => { "from" => nil, "to" => 10 },
          "apartments_per_floor" => { "from" => nil, "to" => 4 }
        }
      )

      sign_in admin
      get admin_audit_log_path(log)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Identificação")
      expect(response.body).to include("Quantidade de andares")
      expect(response.body).to include("Apartamentos por andar")
      expect(response.body).not_to include("Floors count")
      expect(response.body).not_to include("Apartments per floor")
    end
  end
end
