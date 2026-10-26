# Correos de Devise con las plantillas editables del panel (Correos › Plantillas):
# invitación, recuperar contraseña y avisos de cambios en la cuenta.
class AccountMailer < Devise::Mailer
  def invitation_instructions(record, token, _opts = {})
    @user = record
    compose("user_invitation", to: record.email, vars: account_vars(vence: expires_on(User::INVITATION_VALID_FOR)),
                               button_url: edit_user_password_url(reset_password_token: token))
  end

  def reset_password_instructions(record, token, opts = {})
    # Si todavía no aceptó la invitación, le llega la invitación de nuevo (con su plazo de 7 días)
    return invitation_instructions(record, token, opts) if record.invitation_pending?

    @user = record
    compose("password_reset", to: record.email, vars: account_vars(vence: expires_on(User.reset_password_within)),
                              button_url: edit_user_password_url(reset_password_token: token))
  end

  def password_change(record, _opts = {})
    @user = record
    compose("password_changed", to: record.email, vars: account_vars, button_url: new_user_password_url)
  end

  # Va al correo anterior (Devise lo pasa en opts[:to])
  def email_changed(record, opts = {})
    @user = record
    compose("email_changed", to: opts[:to].presence || record.email, vars: account_vars)
  end

  private

  def account_vars(**extra)
    {
      nombre: @user.name, primer_nombre: @user.name.to_s.split.first, correo: @user.email, rol: @user.role_label,
      invitado_por: @user.invited_by&.name || "El equipo de #{settings.site_name}"
    }.merge(extra)
  end

  # Hasta cuándo sirve el enlace, contando desde que se generó (o desde ahora en la vista previa)
  def expires_on(valid_for)
    I18n.l(((@user.reset_password_sent_at || Time.current) + valid_for).in_time_zone, format: :long)
  end
end
