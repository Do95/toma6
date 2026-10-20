# Calcula el estimado del cotizador público a partir de lo que eligió la persona.
# Nunca confía en precios enviados por el navegador: todo sale de la base de datos.
#
# selections: [{ "service_id" => 1, "options" => { "12" => 1, "15" => 3 } }]
# plan_id:    plan con precio cerrado (opcional). Los servicios que cubre no suman su
#             precio base, solo sus extras. El combo se aplica solo a los servicios
#             sumados fuera del plan.
class QuoteEstimator
  Line = Struct.new(:service_id, :service, :label, :quantity, :unit_price, :total, :note, keyword_init: true)

  attr_reader :lines, :subtotal, :discount, :total, :services_count, :plan

  def initialize(selections, plan_id: nil, settings: SiteSetting.current)
    @settings = settings
    @raw = Array(selections)
    @plan = Plan.visible.includes(:services).find_by(id: plan_id) if plan_id.present?
    calculate
  end

  def snapshot
    lines.map { |l| l.to_h.compact.transform_values { |v| v.is_a?(BigDecimal) ? v.to_f : v } }
  end

  def discount_percent = applies_bundle? ? @settings.bundle_discount_percent.to_d : 0

  private

  def calculate
    @lines = []
    included = @plan ? @plan.services.map(&:id) : []
    if @plan
      @lines << Line.new(service_id: nil, service: "Plan #{@plan.title}", label: "Plan #{@plan.title}", quantity: 1,
                         unit_price: @plan.price, total: @plan.price, note: @plan.feature_list.join(" · ").presence)
    end

    ids = @raw.map { |s| s["service_id"] || s[:service_id] }.compact.map(&:to_i).uniq
    services = Service.visible.quotable.includes(:options).where(id: ids).index_by(&:id)

    ids.each do |sid|
      service = services[sid] or next
      raw = @raw.find { |s| (s["service_id"] || s[:service_id]).to_i == sid }
      chosen = (raw["options"] || raw[:options] || {}).to_h.transform_keys(&:to_i)

      base = included.include?(sid) ? 0 : service.base_price
      @lines << Line.new(service_id: sid, service: service.title, label: service.title, quantity: 1, unit_price: base, total: base,
                         note: ("Incluido en el plan #{@plan.title}" if included.include?(sid)))

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

    extra = @lines.select { |l| l.service_id && !included.include?(l.service_id) }
    @services_count = extra.map(&:service_id).uniq.size
    @subtotal = @lines.sum { |l| l.total.to_d }
    @discount = (extra.sum { |l| l.total.to_d } * discount_percent / 100).round(2)
    @total = @subtotal - @discount
  end

  def applies_bundle?
    @settings.bundle_discount? && @services_count.to_i >= @settings.bundle_min_services.to_i
  end
end
