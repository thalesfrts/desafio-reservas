class TicketStatusesController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  before_action :set_ticket_status, only: %i[ show edit update destroy ]

  # GET /ticket_statuses or /ticket_statuses.json
  def index
    @ticket_statuses = TicketStatus.all
  end

  # GET /ticket_statuses/new
  def new
    @ticket_status = TicketStatus.new
  end

  # GET /ticket_statuses/1/edit
  def edit
  end

  # POST /ticket_statuses or /ticket_statuses.json
  def create
    @ticket_status = TicketStatus.new(ticket_status_params)

    if @ticket_status.save
      audit_action(
        action: "ticket_status.created",
        auditable: @ticket_status,
        change_set: audit_change_set_for(@ticket_status)
      )

      redirect_to ticket_statuses_path, notice: "Status criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /ticket_statuses/1 or /ticket_statuses/1.json
  def update
    if @ticket_status.update(ticket_status_params)
      audit_action(
        action: "ticket_status.updated",
        auditable: @ticket_status,
        change_set: audit_change_set_for(@ticket_status)
      )

      redirect_to ticket_statuses_path, notice: "Status atualizado com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /ticket_statuses/1 or /ticket_statuses/1.json
  def destroy
    removed_status_snapshot = audit_snapshot_for(@ticket_status, exclude: %w[created_at updated_at])

    if @ticket_status.destroy
      audit_action(
        action: "ticket_status.deleted",
        auditable: @ticket_status,
        context_data: removed_status_snapshot
      )

      redirect_to ticket_statuses_path, notice: "Status excluído com sucesso.", status: :see_other
    else
      redirect_to ticket_statuses_path, alert: ticket_status_destroy_error, status: :see_other
    end
  end

  private

    def set_ticket_status
      @ticket_status = TicketStatus.find(params[:id])
    end

    def ticket_status_params
      params.require(:ticket_status).permit(:name, :is_default, :is_final)
    end

    def ticket_status_destroy_error
      return "Esse é um status padrão do sistema, não é permitido excluir. Você pode apenas editar o nome dele." if @ticket_status.is_default?
      return "Este status não pode ser excluído porque já está vinculado a um ou mais chamados." if @ticket_status.tickets.exists?

      @ticket_status.errors.full_messages.to_sentence.presence || "Não foi possível excluir este status."
    end
end
