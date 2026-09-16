module Admin
  class UnitsController < BaseController
    def index
      units = Unit.includes(:block).order(:block_id, :identifier)

      if params[:block_id].present?
        units = units.where(block_id: params[:block_id])
      end

      if params[:q].present?
        q = "%#{params[:q].strip}%"
        units = units.where("units.identifier ILIKE ?", q)
      end

      render json: units.limit(200).map { |u|
        {
          id: u.id,
          label: "Apartamento #{u.identifier}"
        }
      }
    end
  end
end
