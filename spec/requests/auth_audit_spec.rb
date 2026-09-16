require "rails_helper"

RSpec.describe "Auth audit", type: :request do
  it "creates audit logs on login and logout" do
    user = create(:user, :administrator, password: "123456", password_confirmation: "123456")

    expect do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "123456"
        }
      }
    end.to change(AuditLog, :count).by(1)

    expect(response).to redirect_to(authenticated_root_path)
    expect(AuditLog.last.action).to eq("security.login.succeeded")
    expect(AuditLog.last.actor).to eq(user)

    expect do
      delete destroy_user_session_path
    end.to change(AuditLog, :count).by(1)

    expect(response).to redirect_to(unauthenticated_root_path)
    expect(AuditLog.last.action).to eq("security.logout.succeeded")
    expect(AuditLog.last.actor).to eq(user)
  end

  it "creates audit log on failed login" do
    user = create(:user, :administrator, password: "123456", password_confirmation: "123456")

    expect do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "senha-errada"
        }
      }
    end.to change(AuditLog, :count).by(1)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(AuditLog.last.action).to eq("security.login.failed")
    expect(AuditLog.last.actor).to be_nil
  end
end
