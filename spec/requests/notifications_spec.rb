require "rails_helper"

RSpec.describe "Notifications", type: :request do
  describe "GET /notifications" do
    it "turns the bell link into a return link to the previous page" do
      user = create(:user, :resident)

      sign_in user
      get notifications_path, headers: { "HTTP_REFERER" => tickets_url }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="/tickets"))
      expect(response.body).to include(%(title="Fechar notificações"))
    end
  end

  describe "DELETE /notifications/destroy_all" do
    it "deletes only the current user's notifications" do
      user = create(:user, :resident)
      other_user = create(:user, :resident)
      actor = create(:user, :administrator)
      ticket = create(:ticket)

      notification = Notification.create!(
        user: user,
        actor: actor,
        ticket: ticket,
        kind: :status_changed,
        title: "Status alterado",
        body: "Administrador alterou o status."
      )
      other_notification = Notification.create!(
        user: other_user,
        actor: actor,
        ticket: ticket,
        kind: :comment_added,
        title: "Novo comentário",
        body: "Administrador comentou no chamado."
      )

      sign_in user

      expect {
        delete destroy_all_notifications_path
      }.to change(Notification, :count).by(-1)

      expect(Notification.exists?(notification.id)).to be(false)
      expect(Notification.exists?(other_notification.id)).to be(true)
      expect(response).to redirect_to(notifications_path)
    end
  end
end
