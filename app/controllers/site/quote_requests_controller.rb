module Site
  class QuoteRequestsController < BaseController
    include SpamProtection
    protect_from_spam only: :create, success_path: -> { quote_request_thanks_path }, form_path: -> { services_path(anchor: "cotizador") }

    # Además de lo anterior, con lo guardado en la base (funciona con o sin caché):
    MAX_PER_EMAIL = 3   # solicitudes por correo en una hora
    MAX_PER_IP = 5      # solicitudes por IP en una hora

    def create
      if (previous = duplicate_request)
        # Doble envío (o reintento): no se crea otra solicitud ni se mandan más correos
        session[:last_quote_request_id] = previous.id
        return redirect_to(quote_request_thanks_path)
      end
      if too_many_requests?
        return redirect_to(services_path(anchor: "cotizador"), status: :see_other,
                           alert: "Ya recibimos varias solicitudes tuyas en la última hora. Te respondemos pronto; si es urgente, escribinos por WhatsApp.")
      end

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

    def duplicate_request
      email = params.dig(:quote_request, :email).to_s.strip
      return if email.blank?
      QuoteRequest.where(created_at: 10.minutes.ago..).where("lower(email) = ?", email.downcase)
                  .find_by(message: params.dig(:quote_request, :message).to_s.strip.presence)
    end

    def too_many_requests?
      recent = QuoteRequest.unscoped.where(created_at: 1.hour.ago..)
      email = params.dig(:quote_request, :email).to_s.strip.downcase
      (email.present? && recent.where("lower(email) = ?", email).count >= MAX_PER_EMAIL) ||
        recent.where(ip_address: request.remote_ip).count >= MAX_PER_IP
    end

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
