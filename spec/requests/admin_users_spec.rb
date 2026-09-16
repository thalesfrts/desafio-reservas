require "rails_helper"

RSpec.describe "Admin users", type: :request do
  describe "GET /admin/users/:id/edit" do
    it "renders role options in pt-BR" do
      admin = create(:user, :administrator)
      user = create(:user, :resident)

      sign_in admin
      get edit_admin_user_path(user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Perfil")
      expect(response.body).to include("Morador")
      expect(response.body).to include("Colaborador")
      expect(response.body).to include("Administrador")
      expect(response.body).not_to include("Resident")
      expect(response.body).not_to include("Collaborator")
      expect(response.body).not_to include("Administrator")
    end
  end
end
