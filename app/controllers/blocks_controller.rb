class BlocksController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  before_action :set_block, only: %i[edit update destroy]

  # GET /blocks
  def index
    @blocks = Block.all
  end

  # GET /blocks/new
  def new
    @block = Block.new
  end

  # GET /blocks/1/edit
  def edit
  end

  # POST /blocks
  def create
    @block = Block.new(block_params)

    if @block.save
      audit_action(
        action: "block.created",
        auditable: @block,
        change_set: audit_change_set_for(@block)
      )

      redirect_to blocks_path, notice: "Bloco criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /blocks/1
  def update
    if @block.update(block_params)
      audit_action(
        action: "block.updated",
        auditable: @block,
        change_set: audit_change_set_for(@block)
      )

      redirect_to blocks_path, notice: "Bloco atualizado com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /blocks/1
  def destroy
    if block_has_links?(@block)
      redirect_to blocks_path, alert: "Bloco possui vínculos, não é possível excluir.", status: :see_other
      return
    end

    removed_block_snapshot = audit_snapshot_for(@block, exclude: %w[created_at updated_at])

    @block.destroy!

    audit_action(
      action: "block.deleted",
      auditable: @block,
      context_data: removed_block_snapshot
    )

    redirect_to blocks_path, notice: "Bloco removido com sucesso.", status: :see_other
  rescue ActiveRecord::InvalidForeignKey
    redirect_to blocks_path, alert: "Bloco possui vínculos, não é possível excluir.", status: :see_other
  end

  private

  def set_block
    @block = Block.accessible_by(current_ability).find(params[:id])
  end

  def block_params
    params.require(:block).permit(:identification, :floors_count, :apartments_per_floor)
  end

  def block_has_links?(block)
    unit_ids = block.units.select(:id)

    Ticket.where(unit_id: unit_ids).exists? || UserUnit.where(unit_id: unit_ids).exists?
  end
end
