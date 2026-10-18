module Admin
  class QuoteRequestsController < ResourceController
    self.resource_class = QuoteRequest
    self.permission_resource = :sales

    def index
      scope = QuoteRequest.kept.recent.includes(:quote)
      scope = scope.where(status: params[:status]) if QuoteRequest::STATUSES.key?(params[:status])
      scope = scope.where("number ILIKE :q OR name ILIKE :q OR email ILIKE :q", q: "%#{params[:q].strip}%") if params[:q].present?
      @records = paginate(scope, per: 25)
    end

    def show
      @logs = @record.activity_logs.limit(20)
    end

    def update
      if @record.update(params.require(:quote_request).permit(:status))
        redirect_to admin_quote_request_path(@record), notice: "Solicitud marcada como «#{@record.status_label}»."
      else
        redirect_to admin_quote_request_path(@record), alert: @record.errors.full_messages.to_sentence
      end
    end

    def convert
      if @record.quote
        return redirect_to edit_admin_quote_path(@record.quote), notice: "Esta solicitud ya tiene una cotización."
      end
      quote = QuoteBuilder.from_request(@record)
      Quote.transaction do
        quote.save!
        @record.update!(status: "converted")
      end
      ActivityLog.record!(@record, "convert", { "cotización" => [nil, quote.number] })
      redirect_to edit_admin_quote_path(quote), notice: "Se creó la cotización #{quote.number}. Revisala antes de enviarla."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_quote_request_path(@record), alert: "No se pudo convertir: #{e.record.errors.full_messages.to_sentence}"
    end
  end
end
