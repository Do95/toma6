module Admin
  # Historial de correos enviados, con su estado y error. Permite reintentar.
  class EmailLogsController < BaseController
    self.permission_resource = :sales

    def index
      scope = EmailLog.recent.includes(:triggered_by)
      scope = scope.where(status: params[:status]) if EmailLog::STATUSES.key?(params[:status])
      scope = scope.where("email_logs.to ILIKE :q OR email_logs.subject ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
      @counts = EmailLog.group(:status).count
      @logs = paginate(scope, per: 40)
    end

    def show
      @log = EmailLog.find(params[:id])
    end

    def body
      log = EmailLog.find(params[:id])
      render html: (log.body_html.presence || "<p style='font-family:sans-serif;padding:20px;color:#666'>El contenido se guarda cuando el correo se arma.</p>").html_safe, layout: false
    end

    def retry
      authorize!(:sales, :write)
      log = EmailLog.find(params[:id])
      return redirect_to(admin_email_log_path(log), alert: "Este correo no se puede reintentar.") unless log.retryable?
      log.retry!
      redirect_to admin_email_log_path(log), notice: "Reintentando el envío…"
    end

    def retry_failed
      authorize!(:sales, :write)
      logs = EmailLog.failed.select(&:retryable?)
      logs.each(&:retry!)
      redirect_to admin_email_logs_path, notice: "Reintentando #{logs.size} correos."
    end

    private

    def required_action = action_name.in?(%w[index show body]) ? :read : :write
  end
end
