json.extract! ticket_status, :id, :name, :is_default, :created_at, :updated_at
json.url ticket_status_url(ticket_status, format: :json)
