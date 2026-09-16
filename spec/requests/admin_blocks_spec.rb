require "rails_helper"

RSpec.describe "Admin blocks", type: :request do
  describe "POST /blocks" do
    it "allows admin to create block" do
      admin = create(:user, :administrator)
      sign_in admin

      expect do
        post blocks_path, params: {
          block: {
            identification: "B",
            floors_count: 2,
            apartments_per_floor: 2
          }
        }
      end.to change(Block, :count).by(1)

      expect(response).to redirect_to(blocks_path)
    end

    it "generates units automatically using floor+apartment pattern" do
      admin = create(:user, :administrator)
      sign_in admin

      expect do
        post blocks_path, params: {
          block: {
            identification: "C",
            floors_count: 2,
            apartments_per_floor: 3
          }
        }
      end.to change(Unit, :count).by(6)

      block = Block.order(:id).last
      identifiers = block.units.order(:identifier).pluck(:identifier)

      expect(identifiers).to eq(%w[101 102 103 201 202 203])
    end
  end

  describe "DELETE /blocks/:id" do
    it "allows admin to delete block when there are no linked residents or tickets" do
      admin = create(:user, :administrator)
      sign_in admin

      block = create(:block, floors_count: 1, apartments_per_floor: 1)

      expect do
        delete block_path(block)
      end.to change(Block, :count).by(-1)

      expect(response).to redirect_to(blocks_path)
      expect(response).to have_http_status(:see_other)
    end

    it "shows a friendly alert when trying to delete a block with linked records" do
      admin = create(:user, :administrator)
      sign_in admin

      block = create(:block, floors_count: 1, apartments_per_floor: 1)
      unit = block.units.first

      create(:user_unit, unit: unit)
      create(:ticket, unit: unit)

      expect do
        delete block_path(block)
      end.not_to change(Block, :count)

      expect(response).to redirect_to(blocks_path)
      follow_redirect!
      expect(response.body).to include("Bloco possui vínculos, não é possível excluir.")
    end
  end
end
