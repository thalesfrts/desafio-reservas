class TicketTypesController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  before_action :set_ticket_type, only: %i[ show edit update destroy ]

  # GET /ticket_types or /ticket_types.json
  def index
    @ticket_types = TicketType.all
  end

  # GET /ticket_types/new
  def new
    @ticket_type = TicketType.new
  end

  # GET /ticket_types/1/edit
  def edit
  end

  # POST /ticket_types or /ticket_types.json
  def create
    @ticket_type = TicketType.new(ticket_type_params)

    if @ticket_type.save
      audit_action(
        action: "ticket_type.created",
        auditable: @ticket_type,
        change_set: audit_change_set_for(@ticket_type)
      )

      redirect_to ticket_types_path, notice: "Tipo de chamado criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /ticket_types/1 or /ticket_types/1.json
  def update
    if @ticket_type.update(ticket_type_params)
      audit_action(
        action: "ticket_type.updated",
        auditable: @ticket_type,
        change_set: audit_change_set_for(@ticket_type)
      )

      redirect_to ticket_types_path, notice: "Tipo de chamado atualizado com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /ticket_types/1 or /ticket_types/1.json
  def destroy
    removed_type_snapshot = audit_snapshot_for(@ticket_type, exclude: %w[created_at updated_at])

    if @ticket_type.destroy
      audit_action(
        action: "ticket_type.deleted",
        auditable: @ticket_type,
        context_data: removed_type_snapshot
      )

      redirect_to ticket_types_path, notice: "Tipo de chamado excluído com sucesso.", status: :see_other
    else
      redirect_to ticket_types_path, alert: ticket_type_destroy_error, status: :see_other
    end
  end

  private

    def set_ticket_type
      @ticket_type = TicketType.find(params[:id])
    end

    def ticket_type_params
      params.require(:ticket_type).permit(:title, :sla_hours, collaborator_ids: [])
    end

    def ticket_type_destroy_error
      return "Este tipo de chamado não pode ser excluído porque já está vinculado a um ou mais chamados." if @ticket_type.tickets.exists?

      @ticket_type.errors.full_messages.to_sentence.presence || "Não foi possível excluir este tipo de chamado."
    end
end
