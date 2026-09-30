class Admin::ReservationsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource # O CanCanCan garante o acesso exclusivo de Admin

  def index
    @reservations = @reservations.includes(:user, :area).order(start_time: :desc)
  end

  def approve
    # CA-01-08: Bloqueio de concorrência com Pessimistic Locking
    ActiveRecord::Base.transaction do
      @reservation.lock!
      
      if @reservation.requested? && @reservation.update(status: :approved)
        audit_action(action: "reservation.approved", auditable: @reservation)
        redirect_to admin_reservations_path, notice: 'Reserva aprovada com sucesso.'
      else
        redirect_to admin_reservations_path, alert: 'Não foi possível aprovar. Verifique conflitos.'
      end
    end
  end

  def deny
    # RN-01-08: Exige motivo não vazio para negação
    if params[:denial_reason].blank?
      redirect_to admin_reservations_path, alert: 'O motivo da negação é obrigatório.'
      return
    end

    if @reservation.update(status: :denied, denial_reason: params[:denial_reason])
      audit_action(action: "reservation.denied", auditable: @reservation)
      redirect_to admin_reservations_path, notice: 'Reserva negada.'
    else
      redirect_to admin_reservations_path, alert: 'Erro ao negar reserva.'
    end
  end

  def destroy
    # RN-01-12: Cancelamento administrativo antes do início
    if @reservation.start_time > Time.current && (@reservation.requested? || @reservation.approved?)
      if @reservation.update(status: :canceled)
        audit_action(action: "reservation.canceled_by_admin", auditable: @reservation)
        redirect_to admin_reservations_path, notice: 'Reserva cancelada.'
      else
        redirect_to admin_reservations_path, alert: 'Erro ao cancelar a reserva.'
      end
    else
      redirect_to admin_reservations_path, alert: 'Esta reserva não pode ser cancelada.'
    end
  end
end