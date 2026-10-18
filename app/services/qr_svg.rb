require "rqrcode_core"

# Dibuja un QR en SVG con la identidad de toma6: puntos redondeados, ojos en
# rojo, logo al centro y un marco opcional con texto ("ESCANEÁ Y COTIZÁ").
# Con logo usa corrección de errores alta (H), así sigue leyéndose aunque el
# logo tape una parte.
class QrSvg
  RED = "#B63830"
  INK = "#171717"
  WHITE = "#FFFFFF"
  M = 10   # tamaño de cada módulo
  Q = 4    # margen (zona de silencio) en módulos

  PALETTES = {
    "brand" => { bg: WHITE, fg: INK, eye: RED, eye_center: INK, badge: INK, band: INK, dots: true },
    "classic" => { bg: WHITE, fg: "#000000", eye: "#000000", badge: "#000000", band: "#000000", dots: false },
    "inverse" => { bg: WHITE, fg: INK, eye: RED, eye_center: INK, badge: RED, band: RED, dots: true, card: INK }
  }.freeze

  def self.render(text, **opts)
    key = ["qr-svg-v9", Digest::MD5.hexdigest([text, opts.sort].inspect)]
    Rails.cache.fetch(key) { new(text, **opts).to_s }
  end

  def initialize(text, style: "brand", logo: true, label: nil)
    @text = text
    @p = PALETTES.fetch(style.to_s, PALETTES["brand"])
    @logo = logo
    @label = label.to_s.strip.upcase.presence
  end

  def to_s
    qr = RQRCodeCore::QRCode.new(@text, level: @logo ? :h : :m)
    # Con logo, un QR de al menos versión 5 (37×37) para que el logo tape menos proporción
    qr = RQRCodeCore::QRCode.new(@text, level: :h, size: 5) if @logo && qr.version < 5
    @n = qr.module_count
    @size = (@n + quiet * 2) * M
    band = @label ? (@size * 0.17).round : 0
    height = @size + band
    hole = logo_hole

    out = +%(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{@size} #{height}" width="#{@size}" height="#{height}">)
    if @p[:card]
      # Tarjeta oscura con el QR en un panel claro
      out << %(<rect width="#{@size}" height="#{height}" rx="#{M * 2}" fill="#{@p[:card]}"/>)
      out << %(<rect x="#{M * 2}" y="#{M * 2}" width="#{@size - M * 4}" height="#{@size - M * 4}" rx="#{M * 1.4}" fill="#{@p[:bg]}"/>)
    else
      out << %(<rect width="#{@size}" height="#{height}" rx="#{@label ? M * 2 : 0}" fill="#{@p[:bg]}"/>)
    end
    out << modules_path(qr, hole)
    [[0, 0], [@n - 7, 0], [0, @n - 7]].each { |r, c| out << eye(r, c) }
    out << logo_badge(hole) if @logo
    out << label_band(band) if @label
    out << "</svg>"
  end

  private

  def px(i) = (i + quiet) * M
  def quiet = @p[:card] ? Q + 2 : Q

  def in_eye?(r, c) = (r < 7 && c < 7) || (r < 7 && c >= @n - 7) || (r >= @n - 7 && c < 7)

  # Rectángulo central (en módulos) que se deja libre para el logo
  def logo_hole
    return nil unless @logo
    w = (@n * 0.28).round
    w += 1 if w.even? != @n.even?
    h = [(w / 2.0).round, 5].max
    h += 1 if h.even? != @n.even?
    r0 = (@n - h) / 2
    c0 = (@n - w) / 2
    { r0: r0, c0: c0, r1: r0 + h - 1, c1: c0 + w - 1 }
  end

  def in_hole?(hole, r, c) = hole && r.between?(hole[:r0], hole[:r1]) && c.between?(hole[:c0], hole[:c1])

  def modules_path(qr, hole)
    d = +""
    @n.times do |r|
      @n.times do |c|
        next unless qr.modules[r][c]
        next if in_eye?(r, c) || in_hole?(hole, r, c)
        x = px(c)
        y = px(r)
        if @p[:dots]
          # Cuadrado con esquinas suavizadas: estilo propio y fácil de leer para cualquier cámara
          k = M * 0.2
          s = M - k * 2
          d << "M#{x + k} #{y}h#{s}a#{k} #{k} 0 0 1 #{k} #{k}v#{s}a#{k} #{k} 0 0 1 -#{k} #{k}h-#{s}a#{k} #{k} 0 0 1 -#{k} -#{k}v-#{s}a#{k} #{k} 0 0 1 #{k} -#{k}z"
        else
          d << "M#{x} #{y}h#{M}v#{M}h-#{M}z"
        end
      end
    end
    %(<path d="#{d}" fill="#{@p[:fg]}"#{' shape-rendering="crispEdges"' unless @p[:dots]}/>)
  end

  # Ojo (patrón de esquina) de 7×7: anillo y centro
  def eye(r, c)
    x = px(c)
    y = px(r)
    # Esquinas apenas suavizadas: más redondeo hace que las cámaras no encuentren el código
    r = @p[:dots] ? 0.5 : 0
    outer = %(<rect x="#{x}" y="#{y}" width="#{7 * M}" height="#{7 * M}" rx="#{M * r * 1.5}" fill="#{@p[:eye]}"/>)
    hole = %(<rect x="#{x + M}" y="#{y + M}" width="#{5 * M}" height="#{5 * M}" rx="#{M * r}" fill="#{@p[:bg]}"/>)
    center = %(<rect x="#{x + 2 * M}" y="#{y + 2 * M}" width="#{3 * M}" height="#{3 * M}" rx="#{M * r * 0.6}" fill="#{@p[:eye_center] || @p[:eye]}"/>)
    outer + hole + center
  end

  def logo_badge(hole)
    x = px(hole[:c0]) + M * 0.3
    y = px(hole[:r0]) + M * 0.3
    w = (hole[:c1] - hole[:c0] + 1) * M - M * 0.6
    h = (hole[:r1] - hole[:r0] + 1) * M - M * 0.6
    pad = M * 0.9
    %(<rect x="#{x}" y="#{y}" width="#{w}" height="#{h}" rx="#{M * 1.2}" fill="#{@p[:badge]}"/>) +
      %(<image x="#{x + pad}" y="#{y + pad}" width="#{w - pad * 2}" height="#{h - pad * 2}" preserveAspectRatio="xMidYMid meet" href="#{self.class.logo_data_uri}"/>)
  end

  def label_band(band)
    y = @size
    text = ERB::Util.html_escape(@label)
    # Si el texto es largo, la letra se achica para que entre en el marco
    max_width = @size * 0.86
    font = [band * 0.42, max_width / (@label.length * 0.8)].min.round
    fit = ""
    %(<path d="M0 #{y}h#{@size}v#{band - M * 2}a#{M * 2} #{M * 2} 0 0 1 -#{M * 2} #{M * 2}h-#{@size - M * 4}a#{M * 2} #{M * 2} 0 0 1 -#{M * 2} -#{M * 2}z" fill="#{@p[:band]}"/>) +
      %(<text x="#{@size / 2}" y="#{y + band / 2}" fill="#{WHITE}" font-family="Archivo, 'Arial Narrow', Arial, Helvetica, sans-serif" font-weight="800" font-stretch="condensed" font-size="#{font}" letter-spacing="#{(font * 0.04).round(1)}" text-anchor="middle" dominant-baseline="central"#{fit}>#{text}</text>)
  end

  def self.logo_data_uri
    @logo_data_uri ||= "data:image/png;base64,#{Base64.strict_encode64(File.binread(Rails.root.join('app/assets/images/site/qr-logo.png')))}"
  end
end
