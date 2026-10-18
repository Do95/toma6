module Site
  # Enlace privado que se le comparte al cliente para ver y aceptar su cotización.
  class PublicQuotesController < BaseController
    before_action :load_quote

    def show; end

    def pdf
      pdf = QuotePdf.new(@quote)
      send_data pdf.render, filename: pdf.filename, type: "application/pdf", disposition: "inline"
    end

    def accept
      if @quote.status.in?(%w[draft sent]) && !@quote.expired?
        @quote.update!(status: "accepted", accepted_at: Time.current)
        MailDispatcher.deliver(QuoteMailer, :accepted_client, { quote: @quote }, record: @quote, template_key: "quote_accepted_client")
        MailDispatcher.deliver(QuoteMailer, :accepted_team, { quote: @quote }, record: @quote, template_key: "quote_accepted_team")
        redirect_to public_quote_path(@quote.token), notice: "¡Gracias! Recibimos tu aceptación y te contactamos para coordinar."
      else
        redirect_to public_quote_path(@quote.token), alert: "Esta cotización ya no se puede aceptar. Escribinos y la actualizamos."
      end
    end

    private

    def load_quote
      @quote = Quote.kept.includes(:items).find_by!(token: params[:token])
    end
  end
end
