module Admin
  class UsersController < BaseController
    load_and_authorize_resource class: "User"

    def index
      @users = @users.order(created_at: :desc)
    end

    def new
    end

    def create
      if @user.save
        audit_action(
          action: "admin.user.created",
          auditable: @user,
          change_set: audit_change_set_for(@user, exclude: %w[created_at updated_at encrypted_password reset_password_token remember_created_at])
        )

        redirect_to admin_users_path, notice: "Usuário criado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(user_params)
        audit_action(
          action: "admin.user.updated",
          auditable: @user,
          change_set: audit_change_set_for(@user, exclude: %w[created_at updated_at encrypted_password reset_password_token remember_created_at])
        )

        redirect_to admin_users_path, notice: "Usuário atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "Você não pode excluir seu próprio usuário."
        return
      end

      if @user.administrator? && User.where(role: :administrator).count == 1
        redirect_to admin_users_path, alert: "Não é permitido excluir o último administrador."
        return
      end

      removed_user_snapshot = audit_snapshot_for(@user, exclude: %w[created_at updated_at encrypted_password reset_password_token remember_created_at])

      @user.destroy!

      audit_action(
        action: "admin.user.deleted",
        context_data: removed_user_snapshot
      )

      redirect_to admin_users_path, notice: "Usuário removido com sucesso."
    end

    private

    def user_params
      permitted = [ :name, :email, :password, :password_confirmation ]
      permitted << :role unless @user == current_user
      p = params.require(:user).permit(*permitted)

      if p[:password].blank?
        p.delete(:password)
        p.delete(:password_confirmation)
      end

      p
    end
  end
end
