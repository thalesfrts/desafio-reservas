require 'rails_helper'

RSpec.describe "Admin::Reservations", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/reservations/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /approve" do
    it "returns http success" do
      get "/admin/reservations/approve"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /deny" do
    it "returns http success" do
      get "/admin/reservations/deny"
      expect(response).to have_http_status(:success)
    end
  end
end
