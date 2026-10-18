# Una visita a un enlace corto. Guarda dispositivo y origen; nunca la IP.
class ShortLinkClick < ApplicationRecord
  belongs_to :short_link

  BOT = /bot|crawl|spider|slurp|preview|facebookexternalhit|whatsapp|telegram|slack|discord|linkedin|twitter|curl|wget|python|headless/i

  def self.bot?(user_agent) = user_agent.to_s.empty? || user_agent.match?(BOT)

  def self.device_for(ua)
    return "Tablet" if ua.match?(/iPad|Tablet|Kindle/i)
    return "Celular" if ua.match?(/Mobi|iPhone|Android/i)
    "Computadora"
  end

  def self.os_for(ua)
    case ua
    when /iPhone|iPad|iOS/ then "iOS"
    when /Android/ then "Android"
    when /Windows/ then "Windows"
    when /Mac OS X|Macintosh/ then "macOS"
    when /Linux/ then "Linux"
    else "Otro"
    end
  end

  def self.browser_for(ua)
    case ua
    when /Instagram/ then "Instagram"
    when /FBAN|FBAV/ then "Facebook"
    when /Edg\// then "Edge"
    when /SamsungBrowser/ then "Samsung"
    when /Firefox|FxiOS/ then "Firefox"
    when /Chrome|CriOS/ then "Chrome"
    when /Safari/ then "Safari"
    else "Otro"
    end
  end

  # Huella anónima del día: permite contar visitantes únicos sin guardar la IP.
  def self.visitor_hash(ip, ua)
    secret = Rails.application.secret_key_base
    Digest::SHA256.hexdigest("#{Date.current}|#{ip}|#{ua}|#{secret}")[0, 20]
  end

  def self.record!(link, request, source:)
    ua = request.user_agent.to_s
    return if bot?(ua)
    ref = URI.parse(request.referer.to_s).host rescue nil
    ref = nil if ref == request.host
    create!(short_link: link, source: source, device: device_for(ua), os: os_for(ua), browser: browser_for(ua),
            referrer_host: ref&.delete_prefix("www."), visitor_hash: visitor_hash(request.remote_ip, ua),
            created_at: Time.current)
    ShortLink.where(id: link.id).update_all(
      ["clicks_count = clicks_count + 1, qr_clicks_count = qr_clicks_count + ?, last_clicked_at = ?",
       source == "qr" ? 1 : 0, Time.current]
    )
  end
end
