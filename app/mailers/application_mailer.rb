class ApplicationMailer < ActionMailer::Base
  default from: proc { ENV.fetch("MAIL_FROM") { "#{SiteSetting.current.site_name} <#{SiteSetting.current.contact_email.presence || 'hola@toma6.com'}>" } }
  layout "mailer"
  helper :application
  helper_method :settings

  private

  def settings = SiteSetting.current

  # Arma un correo a partir de su plantilla editable. Si la plantilla está
  # desactivada o no hay destinatario, no se envía (queda "No enviado").
  def compose(key, to:, vars:, details: nil, button_url: nil, reply_to: nil)
    template = EmailTemplate.for(key)
    recipients = template.team? ? template.recipient_list(to) : Array(to).compact_blank
    test = params.is_a?(Hash) && params[:to_override].present?
    recipients = [params[:to_override]] if test
    return if (!template.enabled? && !test) || recipients.empty?

    content = template.render(common_vars.merge(vars))
    content[:subject] = "[Prueba] #{content[:subject]}" if test
    @heading = content[:heading]
    @body_html = content[:body_html]
    @button_label = content[:button_label]
    @button_url = button_url
    @details = details
    mail(to: recipients, subject: content[:subject], reply_to: reply_to.presence,
         template_path: "mailers", template_name: "transactional")
  end

  def common_vars
    { sitio: settings.site_name, correo_sitio: settings.contact_email, whatsapp: settings.whatsapp_number }
  end

  def team_inbox = settings.notification_email.presence || settings.contact_email
  def fmt_date(date) = date ? I18n.l(date, format: :long) : "a definir"
  def fmt_money(value)
    amount = value.to_d
    precision = amount.frac.zero? ? 0 : 2
    "#{settings.currency_symbol}#{ActiveSupport::NumberHelper.number_to_rounded(amount, precision: precision, delimiter: ',', separator: '.')}"
  end
  def site_url(path) = "#{settings.public_base_url}#{path}"
end
