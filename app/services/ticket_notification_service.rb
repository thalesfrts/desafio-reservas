class TicketNotificationService
  def initialize(ticket:, actor:)
    @ticket = ticket
    @actor = actor
  end

  def notify_comment_created
    create_notifications(
      kind: :comment_added,
      title: "Novo comentário no chamado ##{formatted_ticket_id}",
      body: "#{actor_name} comentou no chamado."
    )
  end

  def notify_status_changed(old_status_name:, new_status_name:)
    create_notifications(
      kind: :status_changed,
      title: "Status alterado no chamado ##{formatted_ticket_id}",
      body: "#{actor_name} alterou de \"#{old_status_name}\" para \"#{new_status_name}\"."
    )
  end

  private

  attr_reader :ticket, :actor

  def formatted_ticket_id
    ticket.id.to_s.rjust(4, "0")
  end

  def actor_name
    actor&.name.presence || "Sistema"
  end

  def recipient_ids
    ids = []
    ids.concat(User.where(role: :administrator).pluck(:id))
    ids.concat(ticket.ticket_type.collaborators.pluck(:id))
    ids.concat(ticket.unit.users.where(role: :resident).pluck(:id))
    ids << ticket.user_id if ticket.user_id.present?

    ids.uniq - [ actor&.id ].compact
  end

  def create_notifications(kind:, title:, body:)
    recipient_ids.each do |recipient_id|
      Notification.create!(
        user_id: recipient_id,
        actor: actor,
        ticket: ticket,
        kind: kind,
        title: title,
        body: body
      )
    end
  end
end
