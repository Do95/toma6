module Site
  class ServicesController < BaseController
    def index
      @services = Service.visible.ordered.includes(:options)
      @quotable = @services.select(&:quotable?)
      @plans = Plan.visible.ordered.includes(:services)
      @quote_request = QuoteRequest.new
    end
  end
end
