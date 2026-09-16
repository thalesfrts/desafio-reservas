module TicketsHelper
  def ticket_status_badge_classes(status)
    return "bg-slate-100 text-slate-700" if status.blank?

    if ticket_status_reopened?(status)
      "bg-amber-100 text-amber-800"
    elsif status.is_final?
      "bg-emerald-100 text-emerald-800"
    elsif status.is_default?
      "bg-sky-100 text-sky-800"
    else
      "bg-violet-100 text-violet-800"
    end
  end

  def ticket_status_transition_kind(status)
    return "Reabertura" if ticket_status_reopened?(status)
    return "Conclusão" if status&.is_final?

    "Andamento"
  end

  def ticket_status_transition_description(status)
    return "Reabre o chamado e reinicia o ciclo do SLA." if ticket_status_reopened?(status)
    return "Conclui o chamado e solicita um parecer." if status&.is_final?
    return "Marca o ponto inicial do fluxo." if status&.is_default?

    "Mantém o chamado em andamento sem encerrar o atendimento."
  end

  def ticket_status_transition_groups(statuses)
    grouped_statuses = statuses.group_by { |status| ticket_status_transition_kind(status) }

    [ "Andamento", "Conclusão", "Reabertura" ].filter_map do |label|
      next if grouped_statuses[label].blank?

      [ label, grouped_statuses[label] ]
    end
  end

  def ticket_status_state_description(status)
    return "Chamado reaberto para um novo ciclo de atendimento." if ticket_status_reopened?(status)
    return "Chamado concluído no fluxo atual." if status&.is_final?
    return "Chamado aberto aguardando o início do atendimento." if status&.is_default?

    "Chamado em andamento dentro do fluxo de atendimento."
  end

  def ticket_status_indicator_ring_classes(status)
    if ticket_status_reopened?(status)
      "border-amber-500 bg-amber-50"
    elsif status&.is_final?
      "border-emerald-500 bg-emerald-50"
    elsif status&.is_default?
      "border-sky-500 bg-sky-50"
    else
      "border-violet-500 bg-violet-50"
    end
  end

  def ticket_status_indicator_dot_classes(status)
    if ticket_status_reopened?(status)
      "bg-amber-500"
    elsif status&.is_final?
      "bg-emerald-500"
    elsif status&.is_default?
      "bg-sky-500"
    else
      "bg-violet-500"
    end
  end

  def ticket_status_reopened?(status)
    I18n.transliterate(status&.name.to_s).downcase.strip == "reaberto"
  end

  def tickets_sort_next_direction(current_sort_by, current_sort_dir, column)
    return "asc" unless current_sort_by == column

    current_sort_dir == "asc" ? "desc" : "asc"
  end

  def tickets_sort_indicator(current_sort_by, current_sort_dir, column)
    return "" unless current_sort_by == column

    current_sort_dir == "asc" ? " ↑" : " ↓"
  end

  def tickets_query_with(overrides = {})
    request.query_parameters.merge(overrides)
  end

  def ticket_sla_badge_classes(ticket)
    case ticket.sla_status_key
    when :breached
      "bg-rose-100 text-rose-800"
    when :at_risk
      "bg-amber-100 text-amber-800"
    when :on_time
      "bg-emerald-100 text-emerald-800"
    else
      "bg-slate-100 text-slate-700"
    end
  end

  def ticket_sla_status_label(ticket)
    case ticket.sla_status_key
    when :breached
      "SLA vencido"
    when :at_risk
      "SLA em risco"
    when :on_time
      "SLA no prazo"
    else
      "Sem SLA"
    end
  end

  def ticket_sla_timing_label(ticket)
    return "Sem prazo configurado" if ticket.sla_due_at.blank?

    delta_seconds = ticket.sla_delta_seconds
    return "Sem prazo configurado" if delta_seconds.nil?

    if delta_seconds.negative?
      prefix = ticket.ticket_status&.is_final? ? "Concluído com atraso de" : "Atrasado em"
      "#{prefix} #{humanize_sla_seconds(delta_seconds.abs)}"
    else
      prefix = ticket.ticket_status&.is_final? ? "Concluído com folga de" : "Restam"
      "#{prefix} #{humanize_sla_seconds(delta_seconds)}"
    end
  end

  def ticket_sla_timing_classes(ticket)
    case ticket.sla_status_key
    when :breached
      "text-rose-600"
    when :at_risk
      "text-amber-600"
    when :on_time
      "text-emerald-600"
    else
      "text-slate-500"
    end
  end

  private

  def humanize_sla_seconds(total_seconds)
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60

    if hours.positive?
      "#{hours}h #{minutes}min"
    else
      "#{minutes}min"
    end
  end
end
