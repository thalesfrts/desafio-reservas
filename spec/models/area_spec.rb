require 'rails_helper'

RSpec.describe Area, type: :model do
  describe 'Validações básicas' do
    it 'é válida com os atributos obrigatórios' do
      area = Area.new(name: 'Piscina', active: true)
      expect(area).to be_valid
    end

    it 'é inválida sem nome' do
      area = Area.new(name: nil)
      area.valid?
      
      expect(area.errors[:name]).not_to be_empty
    end
  end

  describe 'RN-01-01: Áreas desativadas' do
    it 'pode ser criada como inativa' do
      area = Area.new(name: 'Quadra em Obras', active: false)
      expect(area).to be_valid
      expect(area.active).to be_falsey
    end
  end
end