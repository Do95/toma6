# PNG de los QR, generado en el momento en Ruby puro (ver QrRaster).
# No necesita libvips, ImageMagick ni ninguna librería del sistema: funciona
# igual en Heroku, en una Mac o en cualquier servidor. No se guardan imágenes.
class QrPng
  class Unavailable < StandardError; end

  SIZES = (256..4096)

  def self.render(svg_or_link = nil, size: 1024, text: nil, style: "brand", logo: true, label: nil)
    size = size.to_i.clamp(SIZES.min, SIZES.max)
    Rails.cache.fetch(["qr-png-v3", Digest::MD5.hexdigest([text, style, logo, label].inspect), size]) do
      QrRaster.new(text, style: style, logo: logo, label: label).to_png(size)
    end
  rescue StandardError => e
    raise Unavailable, "No se pudo generar el PNG (#{e.class}: #{e.message})"
  end

  def self.for_link(link, size: 1024)
    render(size: size, text: link.qr_url, style: link.qr_style, logo: link.qr_logo, label: link.qr_label)
  end

  def self.available? = true
end
