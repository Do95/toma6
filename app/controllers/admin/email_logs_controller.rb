module Admin
  # Historial de correos enviados, con su estado y error. Permite reintentar y eliminar.
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

    def destroy
      log = EmailLog.find(params[:id])
      return redirect_to(admin_email_log_path(log), alert: "Este correo se está enviando ahora: esperá a que termine.") unless log.deletable?
      log.destroy!
      ActivityLog.record!(nil, "purge", { "correo del historial" => [log.display_name, nil] })
      redirect_to admin_email_logs_path(list_filters), notice: "Se eliminó el correo del historial.", status: :see_other
    end

    # Elimina los seleccionados o, con failed=1, todos los que fallaron
    def bulk_destroy
      scope = params[:failed] == "1" ? EmailLog.failed : EmailLog.where(id: Array(params[:ids]).map(&:to_i))
      count = scope.where.not(status: "sending").delete_all
      ActivityLog.record!(nil, "purge", { "correos del historial" => [nil, "#{count} eliminados"] }) if count.positive?
      redirect_to admin_email_logs_path(list_filters), notice: "Se #{count == 1 ? 'eliminó 1 correo' : "eliminaron #{count} correos"} del historial.", status: :see_other
    end

    private

    # Al volver a la lista se conservan el filtro y la búsqueda
    def list_filters = params.permit(:status, :q).to_h.compact_blank

    def required_action
      case action_name
      when "index", "show", "body" then :read
      when "destroy", "bulk_destroy" then :delete
      else :write
      end
    end
  end
end
