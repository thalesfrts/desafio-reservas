require 'rails_helper'

RSpec.describe Reservation, type: :model do
  describe 'RN-01-02: Validações de data e hora' do
    it 'recusa solicitações com horário de início no passado' do
      reserva = Reservation.new(start_time: 1.day.ago, end_time: 1.hour.from_now)
      reserva.valid?
      
      expect(reserva.errors[:start_time]).to include("deve ser uma data e horário no futuro")
    end

    it 'recusa solicitações onde o fim é antes do início' do
      reserva = Reservation.new(start_time: 2.hours.from_now, end_time: 1.hour.from_now)
      reserva.valid?
      
      expect(reserva.errors[:end_time]).to include("deve ser posterior ao horário de início")
    end
  end

  describe 'RN-01-05 e RN-01-07: Conflito de intervalos' do
    it 'impede a criação de reserva conflitante se já houver uma aprovada' do
      # Simulamos uma área e uma reserva já aprovada
      area = Area.create!(name: 'Churrasqueira', active: true)
      Reservation.create!(area: area, user_id: 1, start_time: 1.day.from_now, end_time: 1.day.from_now + 2.hours, status: :approved)

      # Tentamos criar uma nova no mesmo horário
      nova_reserva = Reservation.new(area: area, user_id: 2, start_time: 1.day.from_now + 1.hour, end_time: 1.day.from_now + 3.hours)
      nova_reserva.valid?

      expect(nova_reserva.errors[:base]).to include("Já existe uma reserva aprovada para esta área neste horário")
    end
  end

  describe 'RN-01-08: Negação fundamentada' do
    it 'exige motivo quando a reserva tem o status negada' do
      reserva = Reservation.new(status: :denied, denial_reason: nil)
      reserva.valid?

      expect(reserva.errors[:denial_reason]).to include("não pode ficar em branco") # ou a mensagem padrão do Rails que configurou
    end
  end
end