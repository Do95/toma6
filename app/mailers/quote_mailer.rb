class QuoteMailer < ApplicationMailer
  def send_quote
    @quote = params[:quote]
    pdf = QuotePdf.new(@quote)
    attachments[pdf.filename] = { mime_type: "application/pdf", content: pdf.render }
    compose("quote_sent_client", to: @quote.client_email, vars: quote_vars(mensaje: params[:message]),
                                 details: { kind: :quote, record: @quote },
                                 button_url: site_url("/c/#{@quote.token}"), reply_to: settings.contact_email)
  end

  def accepted_client
    @quote = params[:quote]
    compose("quote_accepted_client", to: @quote.client_email, vars: quote_vars,
                                     button_url: site_url("/c/#{@quote.token}"), reply_to: settings.contact_email)
  end

  def accepted_team
    @quote = params[:quote]
    compose("quote_accepted_team", to: team_inbox, vars: quote_vars,
                                   button_url: site_url("/admin/cotizaciones/#{@quote.id}"))
  end

  private

  def quote_vars(mensaje: nil)
    q = @quote
    {
      nombre: q.client_name, primer_nombre: q.client_name.to_s.split.first, numero: q.number, titulo: q.title,
      total: q.money(q.total), valida_hasta: fmt_date(q.valid_until), fecha_evento: fmt_date(q.event_date),
      mensaje: mensaje.to_s
    }
  end
end
