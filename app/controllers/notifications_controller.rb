class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    store_notifications_return_path
    @notifications = current_user.notifications.includes(:actor, :ticket).recent.limit(100)
  end

  def update
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!

    redirect_back fallback_location: notifications_path
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    redirect_to notifications_path, notice: "Todas as notificações foram marcadas como lidas."
  end

  def destroy_all
    current_user.notifications.destroy_all

    redirect_to notifications_path, notice: "Todas as notificações foram apagadas."
  end

  private

  def store_notifications_return_path
    return if request.referer.blank?
    return unless (safe_referer = url_from(request.referer))

    referer_path = URI.parse(safe_referer).request_uri
    return if referer_path == notifications_path

    session[:notifications_return_to] = referer_path
  rescue URI::InvalidURIError
    nil
  end
end
