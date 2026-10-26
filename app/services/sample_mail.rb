# Datos para la vista previa y las pruebas de las plantillas: usa la última
# solicitud o cotización real y, si todavía no hay, una de ejemplo.
class SampleMail
  MAP = {
    "quote_request_client" => [QuoteRequestMailer, :confirm_client, :request],
    "quote_request_team" => [QuoteRequestMailer, :notify_team, :request],
    "quote_sent_client" => [QuoteMailer, :send_quote, :quote],
    "quote_accepted_client" => [QuoteMailer, :accepted_client, :quote],
    "quote_accepted_team" => [QuoteMailer, :accepted_team, :quote],
    "user_invitation" => [AccountMailer, :invitation_instructions, :account],
    "password_reset" => [AccountMailer, :reset_password_instructions, :account],
    "password_changed" => [AccountMailer, :password_change, :account],
    "email_changed" => [AccountMailer, :email_changed, :account]
  }.freeze

  # Los correos de la cuenta usan un enlace de ejemplo que no sirve para entrar
  SAMPLE_TOKEN = "enlace-de-ejemplo"

  def self.build(key, user: nil)
    mailer, action, kind = MAP.fetch(key)
    params = kind == :account ? {} : params_for(kind)
    mailer.with(params.merge(to_override: "vista-previa@ejemplo.com")).public_send(action, *account_args(action, kind, user)).message
  end

  # La prueba se envía siempre a quien la pide (nunca al cliente real).
  def self.deliver_test(key, to)
    mailer, action, kind = MAP.fetch(key)
    if kind == :account
      return MailDispatcher.deliver(mailer, action, { to_override: to }, args: account_args(action, kind, User.find_by(email: to) || User.kept.first), template_key: key)
    end
    record = kind == :request ? QuoteRequest.kept.last : Quote.kept.last
    return nil unless record
    params = (kind == :request ? { quote_request: record } : { quote: record, message: "Mensaje de prueba." }).merge(to_override: to)
    MailDispatcher.deliver(mailer, action, params, template_key: key)
  end

  def self.account_args(action, kind, user)
    return [] unless kind == :account
    user ||= sample_user
    action.in?(%i[invitation_instructions reset_password_instructions]) ? [user, SAMPLE_TOKEN] : [user]
  end

  # Para la vista previa: una persona invitada que todavía no entró
  def self.sample_user
    User.new(id: 0, name: "Andrea Martínez", email: "andrea@ejemplo.com", role: "editor",
             invited_at: Time.current, reset_password_sent_at: Time.current, invited_by: User.kept.find_by(role: "admin"))
  end

  def self.params_for(kind)
    if kind == :request
      { quote_request: QuoteRequest.kept.last || sample_request }
    else
      { quote: Quote.kept.last || sample_quote, message: "Gracias por la charla de ayer. Armamos la propuesta con lo que hablamos." }
    end
  end

  def self.sample_request
    QuoteRequest.new(id: 0, number: "SOL-0000-0000", name: "Andrea Martínez", email: "andrea@ejemplo.com", phone: "+503 7000 0000",
                     event_date: 2.months.from_now.to_date, location: "San Salvador", message: "Es una boda de 120 personas.",
                     selections: [{ "service" => "Fotografía", "label" => "Fotografía", "quantity" => 1, "unit_price" => 180, "total" => 180 },
                                  { "service" => "Fotografía", "label" => "Duración: Media jornada (4 h)", "quantity" => 1, "unit_price" => 120, "total" => 120 }],
                     subtotal: 300, discount: 0, estimated_total: 300)
  end

  def self.sample_quote
    q = Quote.new(id: 0, number: "COT-0000-0000", token: "ejemplo", client_name: "Andrea Martínez", client_email: "andrea@ejemplo.com",
                  title: "Boda — cobertura completa", issued_on: Date.current, valid_until: 15.days.from_now.to_date,
                  currency_symbol: "$", tax_name: SiteSetting.current.tax_name, tax_rate: SiteSetting.current.quote_tax_rate,
                  subtotal: 1000, tax_amount: SiteSetting.current.quote_tax_rate.to_d * 10, total: 1000 + SiteSetting.current.quote_tax_rate.to_d * 10)
    q.items.build(description: "Fotografía", quantity: 1, unit_price: 1000, total: 1000)
    q
  end
end
