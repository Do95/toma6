module Site
  class ServicesController < BaseController
    def index
      @services = Service.visible.ordered.includes(:options)
      @quotable = @services.select(&:quotable?)
      @quote_request = QuoteRequest.new
    end
  end
end
