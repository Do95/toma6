# Calcula el estimado del cotizador público a partir de lo que eligió la persona.
# Nunca confía en precios enviados por el navegador: todo sale de la base de datos.
#
# selections: [{ "service_id" => 1, "options" => { "12" => 1, "15" => 3 } }]
class QuoteEstimator
  Line = Struct.new(:service_id, :service, :label, :quantity, :unit_price, :total, keyword_init: true)

  attr_reader :lines, :subtotal, :discount, :total, :services_count

  def initialize(selections, settings: SiteSetting.current)
    @settings = settings
    @raw = Array(selections)
    calculate
  end

  def snapshot
    lines.map { |l| l.to_h.transform_values { |v| v.is_a?(BigDecimal) ? v.to_f : v } }
  end

  def discount_percent = applies_bundle? ? @settings.bundle_discount_percent.to_d : 0

  private

  def calculate
    @lines = []
    ids = @raw.map { |s| s["service_id"] || s[:service_id] }.compact.map(&:to_i).uniq
    services = Service.visible.quotable.includes(:options).where(id: ids).index_by(&:id)

    ids.each do |sid|
      service = services[sid] or next
      raw = @raw.find { |s| (s["service_id"] || s[:service_id]).to_i == sid }
      chosen = (raw["options"] || raw[:options] || {}).to_h.transform_keys(&:to_i)

      @lines << Line.new(service_id: sid, service: service.title, label: service.title,
                         quantity: 1, unit_price: service.base_price, total: service.base_price)

      picked_groups = {}
      service.visible_options.each do |opt|
        qty = chosen[opt.id].to_i
        next unless qty.positive?
        case opt.kind
        when "addon"
          qty = 1
        when "choice"
          next if picked_groups[opt.group_name]
          picked_groups[opt.group_name] = true
          qty = 1
        when "quantity"
          qty = qty.clamp(opt.min_quantity, opt.max_quantity)
          next unless qty.positive?
        end
        total = opt.price * qty
        label = opt.kind == "choice" ? "#{opt.group_name}: #{opt.name}" : opt.name
        @lines << Line.new(service_id: sid, service: service.title, label: label,
                           quantity: qty, unit_price: opt.price, total: total)
      end
    end

    @services_count = @lines.map(&:service_id).uniq.size
    @subtotal = @lines.sum { |l| l.total.to_d }
    @discount = (@subtotal * discount_percent / 100).round(2)
    @total = @subtotal - @discount
  end

  def applies_bundle?
    @settings.bundle_discount? && @services_count.to_i >= @settings.bundle_min_services.to_i
  end
end
