module Admin
  class UserUnitsController < BaseController
    load_and_authorize_resource class: "UserUnit"

    def index
      @user_unit = UserUnit.new
      @user_units = UserUnit.includes(:user, unit: :block).order(created_at: :desc)
      @residents = User.resident.order(:name)
      @blocks = Block.order(:identification)
    end

    def create
      @user_unit = UserUnit.new(user_unit_params)

      if @user_unit.save
        audit_action(
          action: "admin.user_unit_link.created",
          auditable: @user_unit,
          change_set: audit_change_set_for(@user_unit)
        )

        redirect_to admin_user_units_path, notice: "Vínculo criado com sucesso."
      else
        redirect_to admin_user_units_path, alert: @user_unit.errors.full_messages.to_sentence
      end
    end

    def destroy
      removed_link_snapshot = audit_snapshot_for(@user_unit, exclude: %w[created_at updated_at])

      @user_unit.destroy!

      audit_action(
        action: "admin.user_unit_link.deleted",
        context_data: removed_link_snapshot
      )

      redirect_to admin_user_units_path, notice: "Vínculo removido com sucesso."
    end

    private

    def user_unit_params
      params.require(:user_unit).permit(:user_id, :unit_id)
    end
  end
end
