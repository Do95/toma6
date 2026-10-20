module Admin
  class PlansController < ResourceController
    self.resource_class = Plan
    self.sortable = true

    private

    def collection = super.includes(:services)

    def record_params
      params.require(:plan).permit(:title, :summary, :features, :price, :price_unit, :badge, :highlighted, :published, service_ids: [])
    end
  end
end
