module Admin
  # Enlaces cortos con QR (toma6.com/l/codigo).
  class ShortLinksController < ResourceController
    self.resource_class = ShortLink

    def index
      scope = ShortLink.kept.recent.includes(:creator)
      scope = scope.where("title ILIKE :q OR code ILIKE :q OR destination_url ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
      if request.format.csv?
        return send_data ShortLinkCsv.export(scope.to_a), type: "text/csv; charset=utf-8",
                         filename: "enlaces-toma6-#{Date.current}.csv"
      end
      @records = paginate(scope, per: 24)
      @week = ShortLinkClick.where(short_link_id: @records.map(&:id), created_at: 7.days.ago..).group(:short_link_id).count
      @totals = { links: ShortLink.kept.count, clicks: ShortLink.kept.sum(:clicks_count), qr: ShortLink.kept.sum(:qr_clicks_count),
                  month: ShortLinkClick.joins(:short_link).merge(ShortLink.kept).where(created_at: 30.days.ago..).count }
    end

    def new
      @record = ShortLink.new(destination_url: params[:url].presence, title: params[:title].presence,
                              qr_style: "brand", qr_logo: true, utm_source: params[:utm_source], utm_medium: params[:utm_medium])
    end

    def show
      if request.format.csv?
        return send_data ShortLinkCsv.export_clicks(@record), type: "text/csv; charset=utf-8",
                         filename: "visitas-#{@record.code}-#{Date.current}.csv"
      end
      clicks = @record.clicks
      since = 29.days.ago.to_date
      daily = clicks.where(created_at: since.beginning_of_day..).group("DATE(created_at)").group(:source).count
      @days = (since..Date.current).map do |d|
        { date: d, qr: daily[[d, "qr"]].to_i, link: daily[[d, "link"]].to_i }
      end
      @stats = {
        unique: clicks.distinct.count(:visitor_hash),
        week: clicks.where(created_at: 7.days.ago..).count,
        devices: clicks.group(:device).count.sort_by { -_2 },
        os: clicks.group(:os).count.sort_by { -_2 },
        browsers: clicks.group(:browser).count.sort_by { -_2 }.first(5),
        referrers: clicks.where.not(referrer_host: nil).group(:referrer_host).count.sort_by { -_2 }.first(6)
      }
      @recent = clicks.order(created_at: :desc).limit(12)
    end

    # El QR se genera en el momento (no se guardan imágenes).
    #   /qr        SVG (vectorial, para imprenta)
    #   /qr.png    PNG; ?size=1024 (256 a 4096)
    #   ?download=1 para descargarlo
    def qr
      svg = QrSvg.render(@record.qr_url, style: @record.qr_style, logo: @record.qr_logo, label: @record.qr_label)
      disposition = params[:download] ? "attachment" : "inline"
      if request.format.png?
        size = params[:size].to_i.positive? ? params[:size].to_i : 1024
        png = QrPng.for_link(@record, size: size)
        send_data png, type: "image/png", disposition: disposition, filename: "qr-#{@record.code}-#{size.clamp(256, 4096)}.png"
      else
        send_data svg, type: "image/svg+xml", disposition: disposition, filename: "qr-#{@record.code}.svg"
      end
    rescue QrPng::Unavailable => e
      Rails.logger.error("[QR] #{e.message}")
      redirect_to admin_short_link_path(@record), alert: "No se pudo generar el PNG. Descargá el SVG (sirve igual para imprimir). Detalle: #{e.message}"
    end

    # Importar muchos enlaces desde un CSV
    def import
      authorize!(:content, :write)
      return render(:import) if request.get?
      file = params[:file]
      return redirect_to(import_admin_short_links_path, alert: "Elegí un archivo CSV.") if file.blank?
      @result = ShortLinkCsv.import(file)
      ActivityLog.record!(nil, "create", { "enlaces importados" => [nil, @result.created.size.to_s] }) if @result.created.any?
      render :import
    rescue ArgumentError => e
      redirect_to import_admin_short_links_path, alert: e.message
    end

    def template
      send_data ShortLinkCsv.template, type: "text/csv; charset=utf-8", filename: "plantilla-enlaces-toma6.csv"
    end

    # Vista previa en vivo mientras se edita (no guarda nada)
    def preview
      code = params[:code].to_s.downcase.parameterize.presence || "ejemplo"
      url = "#{settings.public_base_url}/l/#{code}?s=qr"
      svg = QrSvg.render(url, style: params[:style].presence_in(ShortLink::STYLES.keys) || "brand",
                              logo: params[:logo] != "0", label: params[:label].to_s.first(32))
      send_data svg, type: "image/svg+xml", disposition: "inline"
    end

    private

    def required_action = action_name.in?(%w[index show qr preview template]) ? :read : super

    def after_save_path = admin_short_link_path(@record)

    def load_record
      @record = ShortLink.kept.find(params[:id])
    end

    def record_params
      params.require(:short_link).permit(:title, :code, :destination_url, :utm_source, :utm_medium, :utm_campaign,
                                         :expires_at, :active, :qr_style, :qr_logo, :qr_label)
    end
  end
end
