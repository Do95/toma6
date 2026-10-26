# Protección contra spam para los formularios públicos (cotizador y cualquier
# formulario de contacto futuro). Capas:
#   1. Campo trampa: un campo invisible que solo completan los bots.
#   2. Tiempo mínimo: marca de tiempo firmada al mostrar el formulario; enviarlo en
#      menos de MIN_SECONDS (o con una marca vieja o adulterada) es de un bot.
#   3. Demasiados envíos por IP en poco tiempo (si hay caché configurado).
#   4. Cloudflare Turnstile, solo si TURNSTILE_SITE_KEY y TURNSTILE_SECRET_KEY están configurados.
# A los bots (1 y 2) se les responde como si todo hubiera salido bien, para no darles
# pistas; a las personas (3 y 4) se les explica qué pasó.
#
#   protect_from_spam only: :create, success_path: -> { gracias_path }, form_path: -> { formulario_path }
#   (en la vista: <%= spam_guard_fields %> dentro del formulario)
module SpamProtection
  
  extend ActiveSupport::Concern

  MIN_SECONDS = 3
  MAX_AGE = 1.day
  HONEYPOT = :website
  STAMP = :form_stamp

  class_methods do
    def protect_from_spam(only:, success_path:, form_path:, per_ip: 10, within: 10.minutes)
      rate_limit to: per_ip, within: within, only: only, name: "public-form",
                 with: -> { reject_spam!(:rate_limit, form_path, "Recibimos muchos envíos desde tu conexión. Esperá unos minutos y volvé a intentarlo.") }
      before_action(only: only) { check_spam!(success_path, form_path) }
    end
  end

  def self.turnstile_site_key = ENV["TURNSTILE_SITE_KEY"].presence
  def self.turnstile_secret = ENV["TURNSTILE_SECRET_KEY"].presence
  def self.turnstile? = turnstile_site_key.present? && turnstile_secret.present?
  def self.stamp_verifier = Rails.application.message_verifier(:spam_protection)

  # Marca de tiempo firmada que va oculta en el formulario
  def self.new_stamp = stamp_verifier.generate(Time.current.to_i, expires_in: MAX_AGE)

  # Al volver a mostrar el formulario con errores se conserva la marca original,
  # así corregir un dato y reenviar rápido no cuenta como «demasiado rápido».
  def self.stamp_for(current) = current.present? && stamp_verifier.verified(current.to_s) ? current : new_stamp

  private

  def check_spam!(success_path, form_path)
    return fake_success!(:honeypot, success_path) if params[HONEYPOT].present?

    return fake_success!(:no_stamp, success_path) if params[STAMP].blank?
    started = SpamProtection.stamp_verifier.verified(params[STAMP].to_s)
    # Vencida (página abierta más de un día) o adulterada: se pide reenviar, por si es una persona
    unless started.is_a?(Integer)
      return reject_spam!(:stale_stamp, form_path, "La página estuvo abierta mucho tiempo. Revisá tus datos y enviá de nuevo.")
    end
    return fake_success!(:too_fast, success_path) if Time.current.to_i - started < MIN_SECONDS

    return if !SpamProtection.turnstile? || turnstile_passed?
    reject_spam!(:turnstile, instance_exec(&form_path), "No pudimos confirmar que no sos un robot. Volvé a intentarlo.")
  end

  def fake_success!(reason, success_path)
    log_spam(reason)
    redirect_to instance_exec(&success_path)
  end

  def reject_spam!(reason, path, message)
    log_spam(reason)
    path = instance_exec(&path) if path.respond_to?(:call)
    redirect_to path, alert: message, status: :see_other
  end

  def log_spam(reason)
    Rails.logger.info("[Antispam] #{controller_path}##{action_name} bloqueado (#{reason}) ip=#{request.remote_ip}")
  end

  # Verificación con Cloudflare. Si Cloudflare no responde, se deja pasar (las otras capas siguen activas).
  def turnstile_passed?
    token = params["cf-turnstile-response"].to_s
    return false if token.blank?
    uri = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    # Almacén de certificados propio: algunas instalaciones de OpenSSL traen el de Ruby
    # configurado para exigir CRL y la verificación fallaría siempre.
    store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, cert_store: store, open_timeout: 5, read_timeout: 5) do |http|
      http.request(Net::HTTP::Post.new(uri).tap do |req|
        req.set_form_data(secret: SpamProtection.turnstile_secret, response: token, remoteip: request.remote_ip)
      end)
    end
    JSON.parse(res.body)["success"] == true
  rescue StandardError => e
    Rails.logger.error("[Antispam] Turnstile no respondió (se deja pasar): #{e.class} #{e.message}")
    true
  end
end
