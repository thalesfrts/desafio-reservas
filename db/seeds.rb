system_statuses = [
  { name: "Aberto", is_default: true, is_final: false, aliases: [] },
  { name: "Em andamento", is_default: false, is_final: false, aliases: [] },
  { name: "Concluido", is_default: false, is_final: true, aliases: [ "Concluído" ] },
  { name: "Reaberto", is_default: false, is_final: false, aliases: [] }
]

system_statuses.each do |attrs|
  names = ([ attrs[:name] ] + attrs[:aliases]).map(&:downcase)

  status = TicketStatus.where("LOWER(name) IN (?)", names).first || TicketStatus.new
  status.assign_attributes(
    name: attrs[:name],
    is_default: attrs[:is_default],
    is_final: attrs[:is_final]
  )
  status.save!
end

TicketStatus.where.not(name: "Aberto").update_all(is_default: false)

if User.where(role: :administrator).none?
  admin_email = ENV.fetch("ADMIN_EMAIL", "admin@admin.com")
  admin_password = ENV.fetch("ADMIN_PASSWORD", "123456")

  User.create!(
    name: "Administrador",
    email: admin_email,
    role: :administrator,
    password: admin_password,
    password_confirmation: admin_password
  )
end
