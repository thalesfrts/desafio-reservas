module Admin::AuditLogsHelper
  ACTION_LABELS = {
    "security.login.succeeded" => "Login realizado com sucesso",
    "security.login.failed" => "Falha no login",
    "security.logout.succeeded" => "Logout realizado com sucesso",
    "security.access_denied" => "Acesso negado",
    "ticket.created" => "Chamado criado",
    "ticket.updated" => "Chamado atualizado",
    "ticket.deleted" => "Chamado excluído",
    "ticket.status_changed" => "Status do chamado alterado",
    "comment.created" => "Comentário criado",
    "block.created" => "Bloco criado",
    "block.updated" => "Bloco atualizado",
    "block.deleted" => "Bloco excluído",
    "ticket_status.created" => "Status de chamado criado",
    "ticket_status.updated" => "Status de chamado atualizado",
    "ticket_status.deleted" => "Status de chamado excluído",
    "ticket_type.created" => "Tipo de chamado criado",
    "ticket_type.updated" => "Tipo de chamado atualizado",
    "ticket_type.deleted" => "Tipo de chamado excluído",
    "admin.user.created" => "Usuário criado",
    "admin.user.updated" => "Usuário atualizado",
    "admin.user.deleted" => "Usuário excluído",
    "admin.user_unit_link.created" => "Vínculo morador-unidade criado",
    "admin.user_unit_link.deleted" => "Vínculo morador-unidade excluído"
  }.freeze

  AUDITABLE_TYPE_LABELS = {
    "Ticket" => "Chamado",
    "Comment" => "Comentário",
    "Block" => "Bloco",
    "TicketStatus" => "Status de chamado",
    "TicketType" => "Tipo de chamado",
    "User" => "Usuário",
    "UserUnit" => "Vínculo morador-unidade"
  }.freeze

  TECHNICAL_CONTEXT_KEYS = %w[method path controller action_name].freeze

  FIELD_LABELS = {
    "id" => "ID",
    "name" => "Nome",
    "title" => "Título",
    "role" => "Perfil",
    "user_id" => "Usuário",
    "description" => "Descrição",
    "sla_due_at" => "Prazo do SLA",
    "sla_hours" => "Prazo (SLA em horas)",
    "sla_started_at" => "Início do SLA",
    "resolved_at" => "Resolvido em",
    "created_at" => "Criado em",
    "updated_at" => "Atualizado em",
    "ticket_status_id" => "Status do chamado",
    "ticket_type_id" => "Tipo de chamado",
    "unit_id" => "Unidade",
    "ticket_id" => "Chamado",
    "identification" => "Identificação",
    "floors_count" => "Quantidade de andares",
    "apartments_per_floor" => "Apartamentos por andar",
    "is_default" => "Status padrão",
    "is_final" => "Status de conclusão",
    "attachments_count" => "Quantidade de anexos",
    "photos_count" => "Quantidade de fotos",
    "from_status" => "Status anterior",
    "to_status" => "Novo status",
    "email" => "E-mail"
  }.freeze

  def audit_action_label(action)
    action_key = action.to_s
    ACTION_LABELS[action_key] || action_key.tr(".", " ").humanize
  end

  def audit_actor_label(actor)
    actor&.name.presence || "Sistema"
  end

  def audit_resource_type_label(auditable_type)
    type_key = auditable_type.to_s
    return "-" if type_key.blank?

    AUDITABLE_TYPE_LABELS[type_key] || type_key.underscore.humanize
  end

  def audit_resource_label(auditable_type, auditable_id)
    type_label = audit_resource_type_label(auditable_type)
    return type_label if auditable_id.blank? || type_label == "-"

    "#{type_label} ##{auditable_id}"
  end

  def audit_context_rows(context_data)
    data = (context_data || {}).to_h.stringify_keys

    data.except(*TECHNICAL_CONTEXT_KEYS).map do |field, value|
      {
        field: audit_field_label(field),
        value: audit_value_label(field, value)
      }
    end
  end

  def audit_change_rows(change_set)
    data = (change_set || {}).to_h.stringify_keys

    data.each_with_object([]) do |(field, transition), rows|
      next unless transition.is_a?(Hash)

      transition_data = transition.stringify_keys

      rows << {
        field: audit_field_label(field),
        from: audit_value_label("#{field}.from", transition_data["from"]),
        to: audit_value_label("#{field}.to", transition_data["to"])
      }
    end
  end

  private

  def audit_field_label(field)
    normalized_field = field.to_s.sub(/\.(from|to)\z/, "")
    FIELD_LABELS[normalized_field] || normalized_field.tr("_", " ").humanize
  end

  def audit_value_label(field, value)
    return "-" if value.nil? || (value.respond_to?(:empty?) && value.empty?)

    reference_value = audit_reference_value(field, value)
    return reference_value if reference_value.present?

    datetime_value = audit_datetime_value(value)
    return datetime_value if datetime_value.present?

    case value
    when TrueClass
      "Sim"
    when FalseClass
      "Não"
    when Array
      value.map { |item| audit_value_label(field, item) }.join(", ")
    when Hash
      value.to_json
    else
      audit_plain_value_label(field, value)
    end
  end

  def audit_plain_value_label(field, value)
    normalized_field = field.to_s.sub(/\.(from|to)\z/, "")

    if normalized_field == "role"
      return role_name(value)
    end

    value
  end

  def audit_reference_value(field, value)
    normalized_field = field.to_s.sub(/\.(from|to)\z/, "")
    return nil unless value.to_s.match?(/\A\d+\z/)

    record_id = value.to_i

    case normalized_field
    when "user_id"
      user = User.find_by(id: record_id)
      user ? "#{user.name} (##{record_id})" : "##{record_id}"
    when "ticket_status_id"
      status = TicketStatus.find_by(id: record_id)
      status ? "#{status.name} (##{record_id})" : "##{record_id}"
    when "ticket_type_id"
      ticket_type = TicketType.find_by(id: record_id)
      ticket_type ? "#{ticket_type.title} (##{record_id})" : "##{record_id}"
    when "unit_id"
      unit = Unit.find_by(id: record_id)
      unit ? "#{unit.identifier} (##{record_id})" : "##{record_id}"
    when "ticket_id"
      "##{record_id}"
    else
      nil
    end
  end

  def audit_datetime_value(value)
    return nil unless value.is_a?(String)

    parsed_time = Time.zone.parse(value)
    return nil unless parsed_time

    I18n.l(parsed_time, format: "%d/%m/%Y %H:%M:%S")
  rescue ArgumentError, TypeError
    nil
  end
end
