class ReservationsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource # O CanCanCan garante que o morador só vê/mexe no que é dele

  def index
    # As reservas já vêm filtradas para o utilizador atual graças ao CanCanCan
    @reservations = @reservations.includes(:area).order(start_time: :desc)
  end

  def new
    @areas = Area.all # Na view, mostraremos apenas as ativas
  end

  def create
    @reservation.user = current_user
    
    if @reservation.save
      audit_action(action: "reservation.created", auditable: @reservation)
      redirect_to reservations_path, notice: 'Reserva solicitada com sucesso.'
    else
      @areas = Area.all
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # RN-01-11: Cancelamento pelo proprietário antes do início
    if @reservation.start_time > Time.current && (@reservation.requested? || @reservation.approved?)
      if @reservation.update(status: :canceled)
        audit_action(action: "reservation.canceled", auditable: @reservation)
        redirect_to reservations_path, notice: 'Reserva cancelada com sucesso.'
      else
        redirect_to reservations_path, alert: 'Erro ao cancelar a reserva.'
      end
    else
      redirect_to reservations_path, alert: 'Esta reserva não pode ser cancelada.'
    end
  end

  private

  def reservation_params
    params.require(:reservation).permit(:area_id, :start_time, :end_time)
  end
end