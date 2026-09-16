module Users
  class SessionsController < Devise::SessionsController
    def create
      super do |user|
        AuditLogger.log(
          actor: user,
          action: "security.login.succeeded",
          context_data: { email: user.email },
          request: request
        )
      end
    ensure
      return if user_signed_in?

      submitted_email = params.dig(:user, :email).to_s.strip.downcase

      AuditLogger.log(
        actor: nil,
        action: "security.login.failed",
        context_data: { email: submitted_email },
        request: request
      )
    end

    def destroy
      user = current_user

      AuditLogger.log(
        actor: user,
        action: "security.logout.succeeded",
        context_data: { email: user.email },
        request: request
      ) if user.present?

      super
    end
  end
end
