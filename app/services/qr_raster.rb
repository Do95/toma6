require "zlib"
require "json"

# Dibuja el QR directamente como PNG en Ruby puro: sin libvips, sin ImageMagick
# y sin gemas nativas (funciona igual en Heroku, en una Mac o en cualquier VPS).
#
# Usa la misma geometría que QrSvg (hereda de él) y escribe un PNG de paleta con
# zlib, que viene con Ruby. El logo y el texto del marco usan máscaras
# pre-renderizadas de la marca (vendor/qr), así no hace falta ninguna fuente
# instalada en el servidor.
class QrRaster < QrSvg
  RAMP = 16 # niveles de suavizado para el logo y el texto

  def to_png(width)
    qr = build_qr
    band_units = @label ? (@size * 0.17).round : 0
    @s = width.to_f / @size
    @w = width
    @h = ((@size + band_units) * @s).round
    @rows = Array.new(@h) { "\x00".b * @w }
    build_palette

    draw_background(band_units)
    draw_modules(qr)
    [[0, 0], [@n - 7, 0], [0, @n - 7]].each { |r, c| draw_eye(r, c) }
    draw_logo(logo_hole) if @logo
    draw_label(band_units) if @label
    encode
  end

  private

  def build_qr
    qr = RQRCodeCore::QRCode.new(@text, level: @logo ? :h : :m)
    qr = RQRCodeCore::QRCode.new(@text, level: :h, size: 5) if @logo && qr.version < 5
    @n = qr.module_count
    @size = (@n + quiet * 2) * M
    qr
  end

  # ---------- Paleta ----------
  def build_palette
    @colors = []
    @index = {}
    add = ->(name, hex) { @index[name] = @colors.size; @colors << rgb(hex) }
    add.(:transparent, "#000000")
    %i[bg fg eye eye_center badge band card].each { |k| add.(k, @p[k] || @p[:eye]) if @p[k] || k == :eye_center }
    add.(:white, WHITE)
    @logo_ramp = ramp(rgb(@p[:badge]), rgb(WHITE))
    @text_ramp = ramp(rgb(@p[:band] || INK), rgb(WHITE))
  end

  def ramp(from, to)
    base = @colors.size
    RAMP.times { |i| t = (i + 1).to_f / RAMP; @colors << from.zip(to).map { |a, b| (a + (b - a) * t).round } }
    base
  end

  def rgb(hex) = hex.delete("#").scan(/../).map { |c| c.to_i(16) }
  def idx(name) = @index.fetch(name).chr

  # ---------- Primitivas ----------
  # Rectángulo con esquinas redondeadas (coordenadas en unidades del SVG)
  def rrect(x, y, w, h, r, name, top: true, bottom: true)
    x0 = x * @s
    x1 = (x + w) * @s
    y0 = (y * @s).round
    y1 = ((y + h) * @s).round
    rad = r * @s
    color = idx(name)
    (y0...[y1, @h].min).each do |py|
      yc = py + 0.5
      inset = 0.0
      if rad.positive?
        d = if top && yc < y0 + rad then (y0 + rad) - yc
            elsif bottom && yc > y1 - rad then yc - (y1 - rad)
            end
        inset = rad - Math.sqrt([rad * rad - d * d, 0].max) if d
      end
      left = (x0 + inset).round
      right = (x1 - inset).round
      next if right <= left || py.negative?
      left = left.clamp(0, @w)
      right = right.clamp(0, @w)
      @rows[py][left, right - left] = color * (right - left)
    end
  end

  # ---------- Capas ----------
  def draw_background(band_units)
    total = @size + band_units
    if @p[:card]
      rrect(0, 0, @size, total, M * 2, :card)
      rrect(M * 2, M * 2, @size - M * 4, @size - M * 4, M * 1.4, :bg)
    else
      rrect(0, 0, @size, total, @label ? M * 2 : 0, :bg)
    end
  end

  def draw_modules(qr)
    hole = logo_hole
    k = @p[:dots] ? M * 0.2 : 0
    @n.times do |r|
      @n.times do |c|
        next unless qr.modules[r][c]
        next if in_eye?(r, c) || in_hole?(hole, r, c)
        rrect(px(c), px(r), M, M, k, :fg)
      end
    end
  end

  def draw_eye(r, c)
    x = px(c)
    y = px(r)
    k = @p[:dots] ? 0.5 : 0
    rrect(x, y, 7 * M, 7 * M, M * k * 1.5, :eye)
    rrect(x + M, y + M, 5 * M, 5 * M, M * k, :bg)
    rrect(x + 2 * M, y + 2 * M, 3 * M, 3 * M, M * k * 0.6, @index.key?(:eye_center) && @p[:eye_center] ? :eye_center : :eye)
  end

  def draw_logo(hole)
    x = px(hole[:c0]) + M * 0.3
    y = px(hole[:r0]) + M * 0.3
    w = (hole[:c1] - hole[:c0] + 1) * M - M * 0.6
    h = (hole[:r1] - hole[:r0] + 1) * M - M * 0.6
    rrect(x, y, w, h, M * 1.2, :badge)
    pad = M * 0.9
    mw, mh, mask = self.class.logo_mask
    box_w = (w - pad * 2) * @s
    box_h = (h - pad * 2) * @s
    scale = [box_w / mw, box_h / mh].min
    dw = (mw * scale).round
    dh = (mh * scale).round
    ox = ((x + pad) * @s + (box_w - dw) / 2).round
    oy = ((y + pad) * @s + (box_h - dh) / 2).round
    blit(mask, mw, mh, ox, oy, dw, dh, @logo_ramp)
  end

  def draw_label(band_units)
    y = @size
    rrect(0, y, @size, band_units, M * 2, :band, top: false)
    meta = self.class.glyph_meta
    max_width = @size * 0.86
    font = [band_units * 0.42, max_width / (@label.length * 0.8)].min.round
    spacing = (font * 0.04).round(1)
    k = font * @s / meta["size"]
    chars = @label.chars.map { |ch| meta["glyphs"][ch] || meta["glyphs"][fallback_char(ch)] || meta["glyphs"][" "] }
    advances = chars.map { |g| g["advance"] * k }
    gap = spacing * @s
    total = advances.sum + gap * (chars.size - 1)
    cap_top = meta["glyphs"]["H"]["y"]
    cap_h = (meta["ascent"] - cap_top) * k
    baseline = (y + band_units / 2.0) * @s + cap_h / 2.0
    pen = @w / 2.0 - total / 2.0
    data = self.class.glyph_data
    chars.each_with_index do |g, i|
      if g["w"].positive? && g["h"].positive?
        gw = (g["w"] * k).round
        gh = (g["h"] * k).round
        gx = (pen + g["x"] * k).round
        gy = (baseline - (meta["ascent"] - g["y"]) * k).round
        blit(data.byteslice(g["offset"], g["w"] * g["h"]), g["w"], g["h"], gx, gy, gw, gh, @text_ramp) if gw.positive? && gh.positive?
      end
      pen += advances[i] + gap
    end
  end

  def fallback_char(ch)
    I18n.transliterate(ch).upcase.then { |t| t.length == 1 ? t : " " }
  end

  # Pinta una máscara alfa (src) escalada a dw×dh en (ox, oy), con la rampa de colores.
  # Promedia por áreas al achicar y usa bilineal al agrandar.
  def blit(src, sw, sh, ox, oy, dw, dh, ramp_base)
    fx = sw.to_f / dw
    fy = sh.to_f / dh
    dh.times do |j|
      py = oy + j
      next if py.negative? || py >= @h
      row = @rows[py]
      sy0 = j * fy
      sy1 = [sy0 + fy, sh].min
      dw.times do |i|
        pxx = ox + i
        next if pxx.negative? || pxx >= @w
        sx0 = i * fx
        a = if fx >= 1.0 || fy >= 1.0
              area(src, sw, sx0, [sx0 + fx, sw].min, sy0, sy1)
            else
              bilinear(src, sw, sh, sx0 + fx / 2 - 0.5, sy0 + fy / 2 - 0.5)
            end
        next if a < 8
        level = (a * RAMP / 255.0).round.clamp(1, RAMP)
        row.setbyte(pxx, ramp_base + level - 1)
      end
    end
  end

  def area(src, sw, x0, x1, y0, y1)
    xa = x0.floor
    xb = [x1.ceil, sw].min
    ya = y0.floor
    yb = y1.ceil
    sum = 0
    n = 0
    (ya...yb).each do |yy|
      base = yy * sw
      (xa...xb).each { |xx| sum += src.getbyte(base + xx).to_i; n += 1 }
    end
    n.zero? ? 0 : sum / n
  end

  def bilinear(src, sw, sh, x, y)
    x = x.clamp(0, sw - 1)
    y = y.clamp(0, sh - 1)
    x0 = x.floor
    y0 = y.floor
    x1 = [x0 + 1, sw - 1].min
    y1 = [y0 + 1, sh - 1].min
    tx = x - x0
    ty = y - y0
    a = src.getbyte(y0 * sw + x0) * (1 - tx) + src.getbyte(y0 * sw + x1) * tx
    b = src.getbyte(y1 * sw + x0) * (1 - tx) + src.getbyte(y1 * sw + x1) * tx
    (a * (1 - ty) + b * ty).round
  end

  # ---------- PNG (paleta de 8 bits) ----------
  def encode
    raw = +"".b
    @rows.each { |row| raw << "\x00".b << row }
    png = +"\x89PNG\r\n\x1A\n".b
    png << chunk("IHDR", [@w, @h, 8, 3, 0, 0, 0].pack("NNCCCCC"))
    png << chunk("PLTE", @colors.flatten.pack("C*"))
    png << chunk("tRNS", "\x00".b) # el índice 0 es transparente (fuera de las esquinas redondeadas)
    png << chunk("IDAT", Zlib::Deflate.deflate(raw, 6))
    png << chunk("IEND", "".b)
  end

  def chunk(type, data)
    [data.bytesize].pack("N") + type.b + data + [Zlib.crc32(type + data)].pack("N")
  end

  # ---------- Recursos precargados ----------
  DIR = File.expand_path("../../vendor/qr", __dir__)

  def self.logo_mask
    @logo_mask ||= begin
      raw = Zlib::Inflate.inflate(File.binread(File.join(DIR, "logo.mask.z")))
      w, h = raw.unpack("NN")
      [w, h, raw.byteslice(8, w * h)]
    end
  end

  def self.glyph_meta = @glyph_meta ||= JSON.parse(File.read(File.join(DIR, "glyphs.json")))
  def self.glyph_data = @glyph_data ||= Zlib::Inflate.inflate(File.binread(File.join(DIR, "glyphs.bin.z")))
end
