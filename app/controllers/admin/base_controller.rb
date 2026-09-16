module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin!

    private

    def ensure_admin!
      authorize! :manage, :all
    end
  end
end
