class QuoteRequestMailer < ApplicationMailer
  # Confirmación automática a quien pidió la cotización
  def confirm_client
    @quote_request = params[:quote_request]
    prices = settings.estimator_shows_prices?
    vars = request_vars
    unless prices
      plan = @quote_request.plan_line
      vars[:total_estimado] = if plan.nil? then "a confirmar en la propuesta"
                              elsif @quote_request.priced_extras? then "desde #{fmt_money(plan['total'])}"
                              else fmt_money(plan["total"])
                              end
    end
    compose("quote_request_client", to: @quote_request.email, vars: vars,
                                    details: { kind: :request, record: @quote_request, prices: prices },
                                    button_url: site_url("/proyectos"), reply_to: settings.contact_email)
  end

  # Aviso al equipo con el detalle y el enlace al panel
  def notify_team
    @quote_request = params[:quote_request]
    compose("quote_request_team", to: team_inbox, vars: request_vars,
                                  details: { kind: :request, record: @quote_request },
                                  button_url: site_url("/admin/solicitudes/#{@quote_request.id}"), reply_to: @quote_request.email)
  end

  private

  def request_vars
    r = @quote_request
    {
      nombre: r.name, primer_nombre: r.name.to_s.split.first, correo: r.email, telefono: r.phone.presence || "sin teléfono",
      empresa: r.company, fecha_evento: fmt_date(r.event_date), lugar: r.location.presence || "a definir",
      mensaje: r.message.presence || "—", servicios: r.selection_lines.map { |l| l["service"] }.uniq.to_sentence,
      total_estimado: fmt_money(r.estimated_total), numero_solicitud: r.number
    }
  end
end
