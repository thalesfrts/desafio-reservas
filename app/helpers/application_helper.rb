module ApplicationHelper
  def root_path_for(user)
    return unauthenticated_root_path unless user
    return authenticated_root_path if user.administrator?

    tickets_path
  end

  def navigation_items_for(user)
    return [] unless user

    if user.administrator?
      return [
        {
          label: "Chamados",
          icon: :ticket,
          children: [
            { label: "Visualizar chamados", path: tickets_path, icon: :list, controllers: %w[tickets comments] },
            { label: "Tipos de chamados", path: ticket_types_path, icon: :tag, controllers: %w[ticket_types] },
            { label: "Status de chamados", path: ticket_statuses_path, icon: :status, controllers: %w[ticket_statuses] }
          ]
        },
        {
          label: "Condominio",
          icon: :building,
          children: [
            { label: "Blocos e unidades", path: blocks_path, icon: :building, controllers: %w[blocks] },
            { label: "Vinculos morador-unidade", path: admin_user_units_path, icon: :link, controllers: %w[admin/user_units admin/units] }
          ]
        },
        { label: "Usuarios", path: admin_users_path, icon: :users, controllers: %w[admin/users] },
        { label: "Auditoria", path: admin_audit_logs_path, icon: :shield, controllers: %w[admin/audit_logs] }
      ]
    end

    if user.collaborator?
      return [
        {
          label: "Chamados",
          icon: :ticket,
          children: [
            { label: "Visualizar chamados", path: tickets_path, icon: :list, controllers: %w[tickets comments] }
          ]
        }
      ]
    end

    [
      {
        label: "Chamados",
        icon: :ticket,
        children: [
          { label: "Meus chamados", path: tickets_path, icon: :list, controllers: %w[tickets comments] }
        ]
      }
    ]
  end

  def navigation_item_active?(item)
    if item[:children].present?
      return item[:children].any? { |child| navigation_item_active?(child) }
    end

    return true if current_page?(item[:path])

    item.fetch(:controllers, []).include?(controller_path)
  end

  def navigation_group_open?(item)
    navigation_item_active?(item)
  end

  def navigation_link_classes(active, mobile: false)
    base = "group flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold transition-all duration-300 ease-out"

    if active
      "#{base} bg-white text-[#3a266b] shadow-sm"
    elsif mobile
      "#{base} text-violet-100 hover:bg-white/12 hover:text-white"
    else
      "#{base} text-violet-100 hover:bg-white/12 hover:text-white"
    end
  end

  def navigation_group_button_classes(active, mobile: false)
    base = "group flex w-full items-center justify-between rounded-xl px-4 py-3 text-left text-sm font-semibold transition-all duration-300 ease-out"

    if active
      "#{base} bg-white text-[#3a266b] shadow-sm"
    elsif mobile
      "#{base} text-violet-100 hover:bg-white/12 hover:text-white"
    else
      "#{base} text-violet-100 hover:bg-white/12 hover:text-white"
    end
  end

  def navigation_sub_link_classes(active)
    base = "flex items-center gap-2 rounded-lg px-3 py-2 text-sm transition-all duration-300 ease-out"

    if active
      "#{base} bg-white text-[#3a266b] font-semibold"
    else
      "#{base} text-violet-100/90 hover:bg-white/10 hover:text-white"
    end
  end

  def navigation_badge_classes(active)
    if active
      "inline-flex h-7 w-7 items-center justify-center rounded-lg bg-[#e9e2ff] text-[#3a266b]"
    else
      "inline-flex h-7 w-7 items-center justify-center rounded-lg bg-white/20 text-white"
    end
  end

  def navigation_icon(icon, classes: "h-4 w-4")
    path = case icon
    when :ticket
             "M9 5h6a2 2 0 012 2v1.5a1.5 1.5 0 000 3V13a2 2 0 01-2 2H9a2 2 0 01-2-2v-1.5a1.5 1.5 0 000-3V7a2 2 0 012-2z"
    when :building
             "M4 21h16M6 21V6a1 1 0 011-1h10a1 1 0 011 1v15M9 10h.01M9 14h.01M9 18h.01M15 10h.01M15 14h.01M15 18h.01"
    when :users
             "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.653-.126-1.277-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M12 12a4 4 0 100-8 4 4 0 000 8z"
    when :user
             "M5.121 17.804A4 4 0 018 16h8a4 4 0 012.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0z"
    when :list
             "M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01"
    when :tag
             "M20 10l-8.586 8.586a2 2 0 01-2.828 0L3 13V3h10l7 7zM7.5 7.5h.01"
    when :status
             "M9 12l2 2 4-4M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
    when :link
             "M10 14a5 5 0 007.07 0l1.41-1.41a5 5 0 00-7.07-7.07L10 6m4 4a5 5 0 00-7.07 0L5.5 11.41a5 5 0 007.07 7.07L14 18"
    when :shield
             "M12 3l7 3v6c0 5-3.5 8.5-7 10-3.5-1.5-7-5-7-10V6l7-3zm0 5a3 3 0 100 6 3 3 0 000-6z"
    else
             "M12 5v14M5 12h14"
    end

    content_tag(:svg, class: classes, xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor") do
      content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "1.8", d: path)
    end
  end

  def page_heading
    if content_for?(:page_heading)
      content_for(:page_heading)
    elsif content_for?(:title)
      content_for(:title).split("|").first.strip
    else
      "Painel"
    end
  end

  def role_label(user)
    return "Administrador" if user.administrator?
    return "Colaborador" if user.collaborator?

    "Morador"
  end

  def role_options_for_select
    User.roles.keys.map { |role| [ role_name(role), role ] }
  end

  def role_name(role)
    {
      "resident" => "Morador",
      "collaborator" => "Colaborador",
      "administrator" => "Administrador"
    }.fetch(role.to_s, role.to_s.humanize)
  end

  def notifications_toggle_path
    return notifications_path unless current_page?(notifications_path)

    session[:notifications_return_to].presence || root_path_for(current_user)
  end

  def notifications_toggle_title
    current_page?(notifications_path) ? "Fechar notificações" : "Notificações"
  end

  def unread_notifications_count
    return 0 unless user_signed_in?

    current_user.notifications.unread.count
  end
end
