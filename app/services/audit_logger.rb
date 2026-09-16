class AuditLogger
  class << self
    def log(actor:, action:, auditable: nil, context_data: {}, change_set: {}, request: nil)
      AuditLog.create!(
        actor: actor,
        action: action,
        auditable: auditable,
        context_data: safe_json(merge_request_context(context_data, request)),
        change_set: safe_json(change_set),
        ip_address: client_ip_from(request),
        request_id: request&.request_id,
        user_agent: request&.user_agent
      )
    rescue StandardError => e
      Rails.logger.error("[AuditLogger] Failed to persist audit event #{action}: #{e.class} - #{e.message}")
      nil
    end

    def build_change_set(record, exclude: %w[created_at updated_at])
      return {} unless record.respond_to?(:saved_changes)

      record.saved_changes.except(*exclude).transform_values do |change|
        old_value, new_value = change
        { from: normalize_value(old_value), to: normalize_value(new_value) }
      end
    end

    def snapshot(record, exclude: [])
      return {} unless record.respond_to?(:attributes)

      record.attributes.except(*exclude).transform_values { |value| normalize_value(value) }
    end

    private

    def merge_request_context(context_data, request)
      data = context_data || {}
      return data unless request

      data.merge(
        method: request.request_method,
        path: request.fullpath,
        controller: request.path_parameters[:controller],
        action_name: request.path_parameters[:action]
      )
    end

    def client_ip_from(request)
      return nil unless request

      forwarded_ips = request.get_header("HTTP_X_FORWARDED_FOR").to_s.split(",").map(&:strip)
      forwarded_ips.find(&:present?) || request.remote_ip
    end

    def normalize_value(value)
      case value
      when Time, Date, DateTime
        value.iso8601
      when Hash
        value.transform_values { |v| normalize_value(v) }
      when Array
        value.map { |v| normalize_value(v) }
      else
        value
      end
    end

    def safe_json(value)
      JSON.parse(JSON.generate(value || {}))
    rescue JSON::GeneratorError, TypeError
      {}
    end
  end
end
