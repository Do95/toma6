module Site
  class QuoteRequestsController < BaseController
    def create
      # Campo trampa contra bots: los humanos no lo ven.
      return redirect_to(quote_request_thanks_path) if params[:website].present?

      selections = parse_selections(params[:selections])
      estimate = QuoteEstimator.new(selections, plan_id: params[:plan_id])
      @quote_request = QuoteRequest.new(request_params.merge(
        plan: estimate.plan, selections: estimate.snapshot, subtotal: estimate.subtotal, discount: estimate.discount,
        estimated_total: estimate.total, ip_address: request.remote_ip, user_agent: request.user_agent.to_s.first(250)
      ))

      if @quote_request.save
        session[:last_quote_request_id] = @quote_request.id
        send_notifications(@quote_request)
        redirect_to quote_request_thanks_path
      else
        @services = Service.visible.ordered.with_photos.includes(:options)
        @quotable = @services.select(&:quotable?)
        @plans = Plan.visible.ordered.includes(:services)
        render "site/services/index", status: :unprocessable_entity
      end
    end

    def thanks
      @quote_request = QuoteRequest.kept.find_by(id: session[:last_quote_request_id])
    end

    private

    def request_params
      params.require(:quote_request).permit(:name, :email, :phone, :company, :event_date, :location, :message)
    end

    # Pase lo que pase con el correo, la solicitud ya está guardada y la persona
    # ve la confirmación. Los errores quedan en Panel → Correos.
    def send_notifications(request)
      MailDispatcher.deliver(QuoteRequestMailer, :confirm_client, { quote_request: request },
                             record: request, template_key: "quote_request_client")
      MailDispatcher.deliver(QuoteRequestMailer, :notify_team, { quote_request: request },
                             record: request, template_key: "quote_request_team")
    rescue StandardError => e
      Rails.logger.error("[QuoteRequest ##{request.id}] Aviso por correo: #{e.message}")
    end

    def parse_selections(raw)
      data = raw.is_a?(String) ? JSON.parse(raw) : raw
      Array(data).first(20)
    rescue JSON::ParserError
      []
    end
  end
end
