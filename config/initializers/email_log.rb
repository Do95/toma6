Rails.application.config.after_initialize do
  ActionMailer::Base.register_observer(EmailLogObserver)
end
