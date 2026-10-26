# Crea una cotización (borrador) a partir de una solicitud del cotizador web.
class QuoteBuilder
  def self.from_request(request)
    settings = SiteSetting.current
    quote = Quote.new(
      quote_request: request,
      title: "Propuesta para #{request.name}",
      client_name: request.name,
      client_company: request.company,
      client_email: request.email,
      client_phone: request.phone,
      event_date: request.event_date,
      event_location: request.location,
      tax_name: settings.tax_name,
      tax_rate: settings.quote_tax_rate,
      notes: settings.quote_default_notes,
      terms: settings.quote_default_terms,
      payment_info: settings.quote_payment_info
    )

    request.selection_lines.each_with_index do |line, i|
      quote.items.build(
        service_id: line["service_id"],
        description: line["label"],
        details: line["note"].presence || (line["label"] == line["service"] ? nil : line["service"]),
        quantity: line["quantity"] || 1,
        unit_price: line["unit_price"] || 0,
        position: i
      )
    end

    if request.discount.to_d.positive? && request.subtotal.to_d.positive?
      quote.discount_type = "percent"
      quote.discount_value = (request.discount.to_d / request.subtotal.to_d * 100).round(2)
    end
    quote
  end
end
