require "rails_helper"

RSpec.describe "Admin user-unit links", type: :request do
  describe "POST /admin/user_units" do
    it "allows admin to link resident to unit" do
      admin = create(:user, :administrator)
      resident = create(:user, :resident)
      unit = create(:unit)

      sign_in admin

      expect do
        post admin_user_units_path, params: {
          user_unit: {
            user_id: resident.id,
            unit_id: unit.id
          }
        }
      end.to change(UserUnit, :count).by(1)

      expect(response).to redirect_to(admin_user_units_path)
    end

    it "does not link non-resident users" do
      admin = create(:user, :administrator)
      collaborator = create(:user, :collaborator)
      unit = create(:unit)

      sign_in admin

      expect do
        post admin_user_units_path, params: {
          user_unit: {
            user_id: collaborator.id,
            unit_id: unit.id
          }
        }
      end.not_to change(UserUnit, :count)

      expect(response).to redirect_to(admin_user_units_path)
    end

    it "shows user-unit validation messages in pt-BR" do
      admin = create(:user, :administrator)

      sign_in admin

      expect do
        post admin_user_units_path, params: {
          user_unit: {
            user_id: "",
            unit_id: ""
          }
        }
      end.not_to change(UserUnit, :count)

      follow_redirect!

      expect(response.body).to include("Morador é obrigatório")
      expect(response.body).to include("Unidade é obrigatório")
      expect(response.body).not_to include("User é obrigatório")
      expect(response.body).not_to include("Unit é obrigatório")
      expect(response.body).not_to include("deve ser morador")
    end

    it "blocks non-admin users" do
      resident = create(:user, :resident)
      target_resident = create(:user, :resident)
      unit = create(:unit)

      sign_in resident

      expect do
        post admin_user_units_path, params: {
          user_unit: {
            user_id: target_resident.id,
            unit_id: unit.id
          }
        }
      end.not_to change(UserUnit, :count)

      expect(response).to redirect_to(tickets_path)
    end
  end
end
