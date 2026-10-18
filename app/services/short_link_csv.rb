require "csv"

# Exportar e importar enlaces cortos en CSV (se abre directo en Excel o Google Sheets).
class ShortLinkCsv
  EXPORT_HEADERS = ["Nombre", "Código", "Enlace corto", "URL dentro del QR", "Destino", "Destino final (con UTM)",
                    "Estado", "Visitas", "Por QR", "Por enlace", "Visitantes únicos", "Última visita",
                    "UTM fuente", "UTM medio", "UTM campaña", "Vence", "Creado", "Creado por"].freeze

  # Encabezados aceptados al importar (español o inglés)
  ALIASES = {
    title: %w[nombre titulo title name],
    destination_url: %w[destino url destination destination_url link enlace],
    code: %w[codigo code slug],
    utm_source: %w[utm_source fuente source],
    utm_medium: %w[utm_medium medio medium],
    utm_campaign: %w[utm_campaign campana campaign],
    qr_label: %w[texto_marco texto marco label qr_label],
    qr_style: %w[estilo style qr_style]
  }.freeze
  MAX_ROWS = 500

  Result = Struct.new(:created, :errors, keyword_init: true)

  def self.export(links)
    uniques = ShortLinkClick.where(short_link_id: links.map(&:id)).group(:short_link_id).distinct.count(:visitor_hash)
    "\uFEFF" + CSV.generate do |csv| # BOM: Excel reconoce los acentos
      csv << EXPORT_HEADERS
      links.each do |l|
        csv << [l.title, l.code, l.short_url, l.qr_url, l.destination_url, l.final_url, l.status_label,
                l.clicks_count, l.qr_clicks_count, l.link_clicks_count, uniques[l.id].to_i,
                l.last_clicked_at&.strftime("%Y-%m-%d %H:%M"), l.utm_source, l.utm_medium, l.utm_campaign,
                l.expires_at&.strftime("%Y-%m-%d %H:%M"), l.created_at.strftime("%Y-%m-%d %H:%M"), l.creator&.name]
      end
    end
  end

  def self.export_clicks(link)
    "\uFEFF" + CSV.generate do |csv|
      csv << ["Fecha", "Hora", "Origen", "Dispositivo", "Sistema", "Navegador o app", "Vino de"]
      link.clicks.order(created_at: :desc).each do |c|
        t = c.created_at.in_time_zone
        csv << [t.strftime("%Y-%m-%d"), t.strftime("%H:%M"), c.source == "qr" ? "QR" : "Enlace", c.device, c.os, c.browser, c.referrer_host]
      end
    end
  end

  def self.template
    "\uFEFF" + CSV.generate do |csv|
      csv << %w[nombre destino codigo utm_source utm_medium utm_campaign texto_marco estilo]
      csv << ["Instagram de toma6", "https://www.instagram.com/toma6sv/", "insta", "flyer", "qr", "feria-2026", "Seguinos", "brand"]
      csv << ["Mesa 1 · Boda Ana & Luis", "https://drive.google.com/…", "", "", "", "", "Fotos de la mesa", "inverse"]
      csv << ["Cotizador", "/servicios#cotizador", "", "", "", "", "Escaneá y cotizá", ""]
    end
  end

  # Crea un enlace por fila. Las filas con error no frenan a las demás.
  def self.import(io)
    rows = parse(io)
    created = []
    errors = []
    rows.first(MAX_ROWS).each_with_index do |row, i|
      attrs = map_row(row)
      next if attrs.values.all?(&:blank?)
      attrs[:qr_style] = "brand" unless ShortLink::STYLES.key?(attrs[:qr_style].to_s)
      link = ShortLink.new(attrs.merge(qr_logo: true))
      if link.save
        created << link
      else
        errors << "Fila #{i + 2}#{" («#{attrs[:title]}»)" if attrs[:title].present?}: #{link.errors.full_messages.to_sentence}"
      end
    end
    errors << "Se procesaron solo las primeras #{MAX_ROWS} filas." if rows.size > MAX_ROWS
    Result.new(created: created, errors: errors)
  end

  def self.parse(io)
    raw = io.read.to_s.b
    text = raw.dup.force_encoding("UTF-8")
    text = raw.encode("UTF-8", "Windows-1252", invalid: :replace, undef: :replace) unless text.valid_encoding?
    text = text.delete_prefix("\uFEFF")
    first = text.lines.first.to_s
    sep = first.count(";") > first.count(",") ? ";" : ","
    CSV.parse(text, headers: true, col_sep: sep, skip_blanks: true).map(&:to_h)
  rescue CSV::MalformedCSVError => e
    raise ArgumentError, "El archivo no es un CSV válido: #{e.message}"
  end

  def self.map_row(row)
    norm = row.to_h.transform_keys { |k| k.to_s.strip.downcase.unicode_normalize(:nfkd).gsub(/[^a-z_ ]/, "").tr(" ", "_") }
    ALIASES.to_h { |attr, names| [attr, names.lazy.map { |n| norm[n] }.find(&:present?).to_s.strip.presence] }
  end
end
