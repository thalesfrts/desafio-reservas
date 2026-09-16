module Admin
  class AuditLogsController < BaseController
    PER_PAGE_OPTIONS = [ 10, 20, 30 ].freeze

    load_and_authorize_resource class: "AuditLog"

    def index
      @filters = params.permit(:q, :audit_action, :actor_id, :auditable_type, :from, :to, :page, :per_page)

      @per_page = @filters[:per_page].to_i
      @per_page = 10 unless PER_PAGE_OPTIONS.include?(@per_page)

      @audit_logs = @audit_logs.includes(:actor).recent
      @audit_logs = @audit_logs.by_action(@filters[:audit_action])
      @audit_logs = @audit_logs.by_actor(@filters[:actor_id])
      @audit_logs = @audit_logs.by_auditable_type(@filters[:auditable_type])
      @audit_logs = @audit_logs.search_text(@filters[:q])

      from_date = parse_date(@filters[:from])
      to_date = parse_date(@filters[:to])

      if from_date.present? && to_date.present? && to_date < from_date
        @date_filter_error = "Não é possível filtrar uma data final antes da data inicial."
      else
        @audit_logs = @audit_logs.from_date(from_date)
        @audit_logs = @audit_logs.to_date(to_date)
      end

      @total_logs = @audit_logs.count
      @total_pages = [ (@total_logs.to_f / @per_page).ceil, 1 ].max

      @page = @filters[:page].to_i
      @page = 1 if @page < 1
      @page = @total_pages if @page > @total_pages

      offset = (@page - 1) * @per_page
      @audit_logs = @audit_logs.offset(offset).limit(@per_page)

      @actors = User.order(:name)
      @actions = AuditLog.distinct.order(:action).pluck(:action)
      @auditable_types = AuditLog.where.not(auditable_type: nil).distinct.order(:auditable_type).pluck(:auditable_type)
    end

    def show
    end

    private

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value)
    rescue ArgumentError
      nil
    end
  end
end
