require "prawn"
require "prawn/table"

# PDF de cotización con la identidad de toma6: banda carbón con el logo,
# acento rojo, tipografía Archivo y tabla de ítems clara.
class QuotePdf
  include Prawn::View

  INK = "171717"
  RED = "B63830"
  MUTED = "6B6B6B"
  LINE = "E2E0DD"
  ZEBRA = "F6F5F3"
  WHITE = "FFFFFF"
  FONT_DIR = Rails.root.join("vendor/fonts")

  def initialize(quote, settings: SiteSetting.current)
    @quote = quote
    @settings = settings
    @document = Prawn::Document.new(page_size: "LETTER", margin: [MARGIN_TOP, PAD, MARGIN_BOTTOM, PAD],
                                    info: { Title: "Cotización #{quote.number}", Author: settings.site_name,
                                            Creator: settings.site_name })
    setup_fonts
    build
  end

  def filename = "cotizacion-#{@quote.number.downcase}.pdf"

  private

  PAD = 48
  MARGIN_TOP = 44
  MARGIN_BOTTOM = 72
  BAND_H = 128

  def setup_fonts
    if File.exist?(FONT_DIR.join("Archivo-Regular.ttf"))
      font_families.update(
        "Archivo" => { normal: FONT_DIR.join("Archivo-Regular.ttf").to_s,
                       bold: FONT_DIR.join("Archivo-Bold.ttf").to_s,
                       italic: FONT_DIR.join("Archivo-Regular.ttf").to_s,
                       bold_italic: FONT_DIR.join("Archivo-Bold.ttf").to_s },
        "ArchivoSemi" => { normal: FONT_DIR.join("Archivo-SemiBold.ttf").to_s },
        "ArchivoCondensed" => { normal: FONT_DIR.join("ArchivoCondensed-ExtraBold.ttf").to_s }
      )
      @body_font, @semi_font, @display_font = "Archivo", "ArchivoSemi", "ArchivoCondensed"
    else
      @body_font = @semi_font = @display_font = "Helvetica"
    end
    font @body_font
    default_leading 2
  end

  def build
    header_band
    move_down 28
    info_columns
    move_down 26
    items_table
    move_down 18
    totals_block
    move_down 26
    notes_blocks
    acceptance_block
    footer_on_every_page
  end

  # ---------- Encabezado ----------
  def header_band
    page_w = bounds.absolute_right + PAD
    page_h = bounds.absolute_top + MARGIN_TOP
    canvas do
      fill_color INK
      fill_rectangle [0, page_h], page_w, BAND_H
      fill_color RED
      fill_rectangle [0, page_h - BAND_H], page_w, 6
      clapper_stripes(page_w - 150, page_h, 150, 22)

      begin
        raise ArgumentError, "sin logo" unless (logo = logo_path)
        image logo, at: [PAD, page_h - 34], fit: [170, 70]
      rescue StandardError
        # PNG entrelazado o formato no soportado: se usa el nombre en texto
        fill_color WHITE
        font(@display_font) { draw_text @settings.site_name.upcase, at: [PAD, page_h - 78], size: 34 }
      end

      fill_color WHITE
      font(@display_font) do
        text_box "COTIZACIÓN", at: [page_w - PAD - 260, page_h - 44], width: 260, align: :right, size: 30
      end
      fill_color "BDBDBD"
      font(@semi_font) do
        text_box "N.º #{@quote.number}", at: [page_w - PAD - 260, page_h - 82], width: 260, align: :right, size: 11
      end
    end
    fill_color INK
    move_cursor_to page_h - BAND_H - 6 - MARGIN_BOTTOM
  end

  # Franja diagonal como la claqueta del logo.
  def clapper_stripes(x, top, w, h)
    save_graphics_state do
      fill_color "2A2A2A"
      fill_rectangle [x, top], w, h
      fill_color RED
      step = 18
      (0..(w / step + 2)).each do |i|
        sx = x + i * step - h
        fill_polygon [sx, top - h], [sx + 9, top - h], [sx + 9 + h, top], [sx + h, top]
      end
    end
  end

  def logo_path
    candidates = []
    candidates << UploadFile.local_path(@settings.pdf_logo) if @settings.pdf_logo.present?
    candidates << UploadFile.local_path(@settings.logo) if @settings.logo.present?
    candidates << Rails.root.join("app/assets/images/site/logo-toma6.png").to_s
    candidates.find { |p| p && File.exist?(p) }
  end

  # ---------- Datos ----------
  def info_columns
    col_w = (bounds.width - 40) / 3.0
    top = cursor
    client = [@quote.client_name, @quote.client_company, @quote.client_tax_id.presence && "NIT/DUI: #{@quote.client_tax_id}",
              @quote.client_email, @quote.client_phone].compact_blank
    project = [@quote.title, @quote.event_date && "Fecha: #{l_date(@quote.event_date)}",
               @quote.event_location.presence && "Lugar: #{@quote.event_location}"].compact_blank
    dates = ["Emitida: #{l_date(@quote.issued_on)}",
             @quote.valid_until && "Válida hasta: #{l_date(@quote.valid_until)}",
             "Moneda: #{@settings.currency_code}"].compact_blank

    heights = [["Para", client], ["Proyecto", project], ["Detalles", dates]].each_with_index.map do |(label, lines), i|
      box = bounding_box([i * (col_w + 20), top], width: col_w) do
        label_text(label)
        move_down 6
        lines.each_with_index do |line, j|
          lead = j.zero? && i < 2
          font(lead ? @semi_font : @body_font) { text line, size: lead ? 11.5 : 9.5, color: lead ? INK : "3F3F3F" }
          move_down 1
        end
      end
      box.height
    end
    move_cursor_to top - heights.max
  end

  def label_text(str)
    fill_color RED
    fill_rectangle [0, cursor], 14, 2.5
    fill_color INK
    move_down 7
    font(@display_font) { text str.upcase, size: 9, character_spacing: 0.6, color: MUTED }
  end

  # ---------- Ítems ----------
  def items_table
    rows = [[
      { content: "Descripción" }, { content: "Cant.", align: :center },
      { content: "Precio unitario", align: :right }, { content: "Total", align: :right }
    ]]
    @quote.items.each do |item|
      desc = "<b>#{escape(item.description)}</b>"
      desc += "\n<font size='8.5'><color rgb='#{MUTED}'>#{escape(item.details)}</color></font>" if item.details.present?
      rows << [
        { content: desc, inline_format: true },
        { content: qty(item.quantity), align: :center },
        { content: @quote.money(item.unit_price), align: :right },
        { content: @quote.money(item.total), align: :right, font: @semi_font }
      ]
    end

    bounding_box([0, cursor], width: bounds.width) do
      table(rows, header: true, width: bounds.width,
                  column_widths: { 1 => 54, 2 => 100, 3 => 100 },
                  cell_style: { size: 9.5, padding: [9, 10, 9, 10], borders: [:bottom], border_color: LINE,
                                border_width: 0.6, text_color: INK, font: @body_font }) do |t|
        t.row(0).font = @display_font
        t.row(0).size = 9
        t.row(0).text_color = WHITE
        t.row(0).background_color = INK
        t.row(0).borders = []
        t.row(0).character_spacing = 0.5
        (1...t.row_length).each { |r| t.row(r).background_color = r.even? ? ZEBRA : WHITE }
      end
    end
  end

  # ---------- Totales ----------
  def totals_block
    box_w = 250
    x = bounds.width - box_w
    lines = [["Subtotal", @quote.money(@quote.subtotal)]]
    if @quote.discount_amount.to_d.positive?
      label = @quote.discount_type == "percent" ? "Descuento (#{pct(@quote.discount_value)})" : "Descuento"
      lines << [label, "– #{@quote.money(@quote.discount_amount)}"]
    end
    lines << ["#{@quote.tax_name} (#{pct(@quote.tax_rate)})", @quote.money(@quote.tax_amount)] if @quote.tax_rate.to_d.positive?

    start_new_page if cursor < 140
    bounding_box([x, cursor], width: box_w) do
      lines.each do |(k, v)|
        font(@body_font) do
          text_box k, at: [0, cursor], width: box_w - 110, size: 10, color: "3F3F3F"
          text_box v, at: [box_w - 110, cursor], width: 110, size: 10, align: :right, color: INK
        end
        move_down 18
      end
      move_down 4
      fill_color RED
      fill_rectangle [0, cursor], box_w, 40
      fill_color WHITE
      font(@display_font) { text_box "TOTAL", at: [14, cursor - 13], width: 100, size: 13, character_spacing: 0.6 }
      font(@display_font) do
        text_box @quote.money(@quote.total), at: [box_w - 174, cursor - 9], width: 160, size: 20, align: :right
      end
      fill_color INK
      move_down 40
    end
  end

  # ---------- Notas, condiciones y pago ----------
  def notes_blocks
    blocks = [["Notas", @quote.notes], ["Condiciones", @quote.terms], ["Forma de pago", @quote.payment_info]]
             .select { |(_, body)| body.present? }
    return if blocks.empty?

    blocks.each do |(title, body)|
      start_new_page if cursor < 110
      bounding_box([0, cursor], width: bounds.width) do
        label_text(title)
        move_down 6
        text body.to_s.strip, size: 9.5, color: "3F3F3F", leading: 3
      end
      move_down 16
    end
  end

  def acceptance_block
    start_new_page if cursor < 140
    move_down 10
    w = (bounds.width - 40) / 2.0
    y = cursor - 40
    stroke_color "9A9A9A"
    line_width 0.7
    [0, 1].each do |i|
      x = i * (w + 40)
      stroke_horizontal_line x, x + w, at: y
      fill_color MUTED
      font(@body_font) do
        draw_text(i.zero? ? "Firma y aclaración del cliente" : "Fecha de aceptación", at: [x, y - 13], size: 8.5)
      end
    end
    fill_color INK
    move_cursor_to y - 30
  end

  # ---------- Pie ----------
  def footer_on_every_page
    contact = [@settings.site_name, @settings.contact_email, @settings.phone.presence || @settings.whatsapp_number,
               @settings.site_url&.sub(%r{\Ahttps?://}, "")].compact_blank.join("   ·   ")
    repeat(:all) do
      canvas do
        fill_color RED
        fill_rectangle [PAD, 50], bounds.width - PAD * 2, 1.2
        fill_color MUTED
        font(@body_font) { draw_text contact, at: [PAD, 32], size: 8 }
      end
    end
    number_pages "Página <page> de <total>", at: [bounds.width - 120, -33], width: 120, align: :right,
                                              size: 8, color: MUTED
    fill_color INK
  end

  # ---------- Utilidades ----------
  def l_date(date) = I18n.l(date, format: :long)
  def pct(value) = "#{value.to_d.to_s('F').sub(/\.0\z/, '')}%"
  def qty(value) = value.to_d.to_s("F").sub(/\.0\z/, "")
  def escape(str) = str.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
end
