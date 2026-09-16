class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do
    AuditLogger.log(
      actor: current_user,
      action: "security.access_denied",
      context_data: {
        denied_controller: controller_path,
        denied_action: action_name
      },
      request: request
    )

    target = (user_signed_in? && current_user.administrator?) ? authenticated_root_path : tickets_path
    redirect_to target, alert: "Acesso Negado: Você não tem permissão para acessar esta página."
  end

  def after_sign_in_path_for(resource)
    return authenticated_root_path if resource.respond_to?(:administrator?) && resource.administrator?
    return tickets_path if resource.respond_to?(:collaborator?) && resource.collaborator?
    return tickets_path if resource.respond_to?(:resident?) && resource.resident?
    super
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def audit_action(action:, auditable: nil, context_data: {}, change_set: {})
    AuditLogger.log(
      actor: current_user,
      action: action,
      auditable: auditable,
      context_data: context_data,
      change_set: change_set,
      request: request
    )
  end

  def audit_change_set_for(record, exclude: %w[created_at updated_at])
    AuditLogger.build_change_set(record, exclude: exclude)
  end

  def audit_snapshot_for(record, exclude: [])
    AuditLogger.snapshot(record, exclude: exclude)
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern, unless: -> { Rails.env.test? }
end
