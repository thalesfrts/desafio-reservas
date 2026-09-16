class TicketsController < ApplicationController
  INDEX_PER_PAGE = 5
  INDEX_PER_PAGE_OPTIONS = [ 5, 10, 20 ].freeze
  INDEX_SORT_OPTIONS = %w[id created_at updated_at sla_due_at ticket_type ticket_status apartment].freeze
  INDEX_SORT_COLUMNS = {
    "id" => "tickets.id",
    "created_at" => "tickets.created_at",
    "updated_at" => "tickets.updated_at",
    "sla_due_at" => "tickets.sla_due_at"
  }.freeze

  before_action :authenticate_user!
  before_action :ensure_resident_has_units!, only: %i[new create]
  load_and_authorize_resource

  # GET /tickets or /tickets.json
  def index
    @filters = params.permit(
      :ticket_status_id,
      :ticket_type_id,
      :unit_id,
      :block_id,
      :sla_state,
      :sort_by,
      :sort_dir,
      :per_page,
      :created_from,
      :created_to,
      :q,
      :period
    )

    @tickets = @tickets
    .includes(:ticket_status, :ticket_type, unit: :block)

    @sort_by = INDEX_SORT_OPTIONS.include?(@filters[:sort_by]) ? @filters[:sort_by] : "created_at"
    @sort_dir = %w[asc desc].include?(@filters[:sort_dir]) ? @filters[:sort_dir] : "desc"
    @per_page = @filters[:per_page].to_i
    @per_page = INDEX_PER_PAGE unless INDEX_PER_PAGE_OPTIONS.include?(@per_page)

    if @filters[:ticket_status_id].present?
      @tickets = @tickets.where(ticket_status_id: @filters[:ticket_status_id])
    end

    if @filters[:ticket_type_id].present?
      @tickets = @tickets.where(ticket_type_id: @filters[:ticket_type_id])
    end

    if @filters[:sla_state].present? && !current_user.resident?
      @tickets = apply_sla_state_filter(@tickets, @filters[:sla_state])
    end

    if current_user.resident? && @filters[:unit_id].present?
      @tickets = @tickets.where(unit_id: @filters[:unit_id])
    end

    if !current_user.resident? && @filters[:block_id].present?
      @tickets = @tickets.joins(unit: :block).where(blocks: { id: @filters[:block_id] })
    end

    if current_user.resident? && @filters[:period].present?
      days = @filters[:period].to_i
      if [ 7, 30, 90 ].include?(days)
        @tickets = @tickets.where("tickets.created_at >= ?", days.days.ago.beginning_of_day)
      end
    end

    from = parse_date_param(@filters[:created_from])
    to = parse_date_param(@filters[:created_to])

    if from.present? && to.present? && to < from
      @date_filter_error = "Não é possível filtrar uma data final antes da data inicial."
    else
      @tickets = @tickets.where("tickets.created_at >= ?", from.beginning_of_day) if from
      @tickets = @tickets.where("tickets.created_at <= ?", to.end_of_day) if to
    end

    if @filters[:q].present?
      query_text = @filters[:q].strip

      if current_user.resident?
        protocol_text = query_text.sub(/^#/, "")
        q = "%#{query_text}%"

        if protocol_text.match?(/\A\d+\z/)
          @tickets = @tickets.joins(:ticket_type).where(
            "tickets.id = :ticket_id OR ticket_types.title ILIKE :q",
            ticket_id: protocol_text.to_i,
            q: q
          )
        else
          @tickets = @tickets.joins(:ticket_type).where("ticket_types.title ILIKE :q", q: q)
        end
      else
        q = "%#{query_text}%"
        @tickets = @tickets.joins(:ticket_type, unit: :block).where(
          "tickets.description ILIKE :q OR ticket_types.title ILIKE :q OR units.identifier ILIKE :q OR blocks.identification ILIKE :q",
          q: q
        )
      end
    end

    @tickets = apply_sort(@tickets, @sort_by, @sort_dir)

    @total_tickets = @tickets.count
    @total_pages = [ (@total_tickets.to_f / @per_page).ceil, 1 ].max

    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page = @total_pages if @page > @total_pages

    offset = (@page - 1) * @per_page
    @tickets = @tickets.offset(offset).limit(@per_page)
  end

  # GET /tickets/1 or /tickets/1.json
  def show
  end

  # GET /tickets/new
  def new
    @ticket.user = current_user
  end

  # GET /tickets/1/edit
  def edit
  end

  # POST /tickets or /tickets.json
  def create
    @ticket.user = current_user
    if current_user.resident? && current_user.units.none?
      redirect_to tickets_path, alert: "Você não possui unidade vinculada. Contate o administrador."
      return
    end

    respond_to do |format|
      if @ticket.save
        audit_action(
          action: "ticket.created",
          auditable: @ticket,
          context_data: {
            ticket_type_id: @ticket.ticket_type_id,
            ticket_status_id: @ticket.ticket_status_id,
            unit_id: @ticket.unit_id,
            attachments_count: @ticket.attachments.count
          },
          change_set: audit_change_set_for(@ticket)
        )

        format.html { redirect_to @ticket, notice: "Chamado aberto com sucesso!" }
        format.json { render :show, status: :created, location: @ticket }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tickets/1 or /tickets/1.json
  def update
    @ticket.acting_user = current_user
    closing_note = params.dig(:ticket, :closing_note).to_s.strip

    respond_to do |format|
      if @ticket.update(ticket_params)
        status_change = @ticket.saved_change_to_ticket_status_id
        if status_change.present?
          old_status_id, new_status_id = status_change
          old_status_name = TicketStatus.find_by(id: old_status_id)&.name || "Sem status"
          new_status_name = TicketStatus.find_by(id: new_status_id)&.name || "Sem status"

          ::TicketNotificationService
            .new(ticket: @ticket, actor: current_user)
            .notify_status_changed(old_status_name: old_status_name, new_status_name: new_status_name)

          if concluding_transition?(old_status_id, new_status_id)
            @ticket.comments.create!(
              user: current_user,
              body: "Status alterado de \"#{old_status_name}\" para \"#{new_status_name}\".\nParecer de conclusão: #{closing_note}"
            )
          elsif !reopening_transition?(old_status_id, new_status_id)
            @ticket.comments.create!(
              user: current_user,
              body: "Status alterado de \"#{old_status_name}\" para \"#{new_status_name}\"."
            )
          end

          audit_action(
            action: "ticket.status_changed",
            auditable: @ticket,
            context_data: {
              from_status: old_status_name,
              to_status: new_status_name
            },
            change_set: audit_change_set_for(@ticket)
          )
        else
          audit_action(
            action: "ticket.updated",
            auditable: @ticket,
            change_set: audit_change_set_for(@ticket)
          )
        end

        format.html { redirect_to @ticket, notice: "Chamado atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @ticket }
      else
        format.html { redirect_to @ticket, alert: @ticket.errors.full_messages.to_sentence }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tickets/1 or /tickets/1.json
  def destroy
    removed_ticket_snapshot = audit_snapshot_for(@ticket, exclude: %w[created_at updated_at])

    @ticket.destroy!

    audit_action(
      action: "ticket.deleted",
      auditable: @ticket,
      context_data: removed_ticket_snapshot
    )

    respond_to do |format|
      format.html { redirect_to tickets_path, notice: "Chamado excluído com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def parse_date_param(value)
    return nil if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def apply_sort(scope, sort_by, sort_dir)
    direction = sort_dir == "asc" ? "ASC" : "DESC"

    case sort_by
    when "ticket_type"
      scope.joins(:ticket_type).order(Arel.sql("ticket_types.title #{direction}, tickets.id DESC"))
    when "ticket_status"
      scope.joins(:ticket_status).order(Arel.sql("ticket_statuses.name #{direction}, tickets.id DESC"))
    when "apartment"
      scope.joins(unit: :block).order(Arel.sql("blocks.identification #{direction}, units.identifier #{direction}, tickets.id DESC"))
    when "sla_due_at"
      scope.order(Arel.sql("tickets.sla_due_at #{direction} NULLS LAST, tickets.id DESC"))
    else
      column = INDEX_SORT_COLUMNS[sort_by] || INDEX_SORT_COLUMNS["created_at"]
      scope.order(Arel.sql("#{column} #{direction}, tickets.id DESC"))
    end
  end

  def apply_sla_state_filter(scope, sla_state)
    reference_time = Time.current

    case sla_state
    when "breached"
      scope.sla_breached(reference_time)
    when "at_risk"
      scope.sla_at_risk(reference_time)
    when "on_time"
      scope.sla_on_time(reference_time)
    else
      scope
    end
  end

  def reopening_transition?(old_status_id, new_status_id)
    old_status = TicketStatus.find_by(id: old_status_id)
    new_status = TicketStatus.find_by(id: new_status_id)

    old_status&.is_final? && !new_status&.is_final?
  end

  def concluding_transition?(old_status_id, new_status_id)
    old_status = TicketStatus.find_by(id: old_status_id)
    new_status = TicketStatus.find_by(id: new_status_id)

    !old_status&.is_final? && new_status&.is_final?
  end

  def ensure_resident_has_units!
    return unless current_user.resident?
    return if current_user.units.exists?

    redirect_to tickets_path, alert: "Você não possui unidade vinculada. Contate o administrador."
  end

  def ticket_params
    permitted =
      if action_name == "create"
        [ :unit_id, :ticket_type_id, :description ]
      elsif current_user.administrator?
        [ :description, :ticket_status_id, :reopen_reason, :closing_note ]
      elsif current_user.collaborator?
        [ :ticket_status_id, :closing_note ]
      else
        []
      end

    params.require(:ticket).permit(*permitted, attachments: [])
  end
end
