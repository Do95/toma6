Devise.setup do |config|
  config.mailer_sender = ENV.fetch("MAIL_FROM", "toma6 <hola@toma6.com>")
  config.parent_mailer = "ApplicationMailer"
  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
  config.navigational_formats = ["*/*", :html, :turbo_stream]
end

# Registra cada inicio de sesión en la bitácora.
Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
  next unless opts[:scope] == :user && opts[:event] == :authentication
  Current.user = user
  Current.ip_address = auth.request.remote_ip
  ActivityLog.record!(user, "sign_in")
end
