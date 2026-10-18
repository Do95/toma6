module Site
  # toma6.com/l/codigo → destino. Cuenta la visita y redirige (302: el destino
  # se puede cambiar sin reimprimir el QR).
  class ShortLinksController < BaseController

    def show
      link = ShortLink.find_by(code: params[:code].to_s.downcase)
      return render(:unavailable, status: (link ? :gone : :not_found)) unless link&.live?

      begin
        # Las visitas de quien está en el panel (probando el enlace) no se cuentan
        ShortLinkClick.record!(link, request, source: params[:s] == "qr" ? "qr" : "link") unless user_signed_in?
      rescue StandardError => e
        Rails.logger.warn("[ShortLink #{link.code}] No se pudo registrar la visita: #{e.message}")
      end
      response.headers["Cache-Control"] = "no-store"
      redirect_to link.final_url, allow_other_host: true, status: :found
    end
  end
end
