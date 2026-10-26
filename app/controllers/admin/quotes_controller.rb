module Admin
  class QuotesController < ResourceController
    self.resource_class = Quote
    self.permission_resource = :sales

    def index
      scope = Quote.kept.includes(:creator, :updater).recent
      scope = scope.where(status: params[:status]) if Quote::STATUSES.key?(params[:status])
      # ?por=DM01: las que creó esa persona (código de usuario)
      scope = scope.where(created_by_id: User.unscoped.find_by(code: params[:por].to_s.upcase)&.id) if params[:por].present?
      @creators = User.where(id: Quote.kept.select(:created_by_id)).ordered
      if params[:q].present?
        q = "%#{params[:q]}%"
        scope = scope.where("number ILIKE :q OR client_name ILIKE :q OR client_company ILIKE :q OR title ILIKE :q", q: q)
      end
      @stats = {
        open_total: Quote.kept.where(status: %w[draft sent]).sum(:total),
        accepted_month: Quote.kept.where(status: "accepted").where(accepted_at: Time.current.all_month).sum(:total),
        sent_count: Quote.kept.where(status: "sent").count,
        acceptance_rate: acceptance_rate
      }
      @records = paginate(scope, per: 25)
    end

    def show
      @logs = @record.activity_logs.limit(30)
    end

    def new
      s = settings
      @record = Quote.new(issued_on: Date.current, tax_name: s.tax_name, tax_rate: s.quote_tax_rate,
                          notes: s.quote_default_notes, terms: s.quote_default_terms, payment_info: s.quote_payment_info,
                          valid_until: Date.current + s.quote_validity_days.days)
      @record.items.build(quantity: 1)
    end

    def edit
      @record.items.build(quantity: 1) if @record.items.empty?
    end

    def pdf
      pdf = QuotePdf.new(@record)
      send_data pdf.render, filename: pdf.filename, type: "application/pdf",
                            disposition: params[:download] ? "attachment" : "inline"
    end

    def duplicate
      authorize!(:sales, :write)
      copy = @record.duplicate!
      redirect_to edit_admin_quote_path(copy), notice: "Se creó #{copy.number} como copia de #{@record.number}."
    end

    def deliver
      authorize!(:sales, :write)
      if @record.client_email.blank?
        return redirect_to admin_quote_path(@record), alert: "Agregá el correo del cliente para enviarla."
      end
      log = MailDispatcher.deliver(QuoteMailer, :send_quote, { quote: @record, message: params[:message].to_s },
                                   record: @record, template_key: "quote_sent_client")
      @record.update!(status: "sent", sent_at: Time.current) if %w[draft sent].include?(@record.status)
      ActivityLog.record!(@record, "send", { "enviada a" => [nil, @record.client_email] })
      log&.reload
      if log.nil? || log.status == "failed"
        redirect_to admin_quote_path(@record), alert: "No se pudo enviar el correo. Revisá el detalle en Correos y reintentá."
      else
        redirect_to admin_quote_path(@record), notice: "Cotización enviada a #{@record.client_email}. El estado del envío se ve en Correos."
      end
    end

    def status
      authorize!(:sales, :write)
      new_status = params[:status].to_s
      return redirect_to(admin_quote_path(@record), alert: "Estado no válido.") unless Quote::STATUSES.key?(new_status)
      stamps = { "sent" => :sent_at, "accepted" => :accepted_at, "rejected" => :rejected_at }
      attrs = { status: new_status }
      attrs[stamps[new_status]] = Time.current if stamps[new_status]
      @record.update!(attrs)
      redirect_to admin_quote_path(@record), notice: "Estado actualizado: #{@record.status_label}."
    end

    private

    def load_record
      @record = Quote.kept.includes(:items).find(params[:id])
    end

    def after_save_path = admin_quote_path(@record)

    def acceptance_rate
      decided = Quote.kept.where(status: %w[accepted rejected]).group(:status).count
      total = decided.values.sum
      total.zero? ? nil : (decided["accepted"].to_i * 100.0 / total).round
    end

    def record_params
      params.require(:quote).permit(
        :title, :client_name, :client_company, :client_email, :client_phone, :client_tax_id,
        :event_date, :event_location, :issued_on, :valid_until, :status,
        :discount_type, :discount_value, :tax_name, :tax_rate, :notes, :terms, :payment_info,
        items_attributes: %i[id service_id description details quantity unit_price position _destroy]
      )
    end
  end
end
