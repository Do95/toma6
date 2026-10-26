module Admin
  # Guarda el orden después de arrastrar elementos en una lista.
  class SortingsController < BaseController
    MODELS = {
      "sections" => Section, "services" => Service, "service_options" => ServiceOption, "plans" => Plan, "projects" => Project, "albums" => Album,
      "media_items" => MediaItem, "media_placements" => MediaPlacement, "categories" => Category, "faqs" => Faq, "process_steps" => ProcessStep,
      "about_values" => AboutValue
    }.freeze

    def update
      model = MODELS.fetch(params[:model]) { return head(:unprocessable_entity) }
      authorize!(model.permission_resource, :write)
      current = model.where(id: Array(params[:ids]).map(&:to_i)).pluck(:id, :position).to_h
      ids = Array(params[:ids]).map(&:to_i).select { |id| current.key?(id) }
      # Las listas están paginadas: se reparten las mismas posiciones que ya tenían
      # los elementos de esta página, así no se mezclan con los de otras páginas.
      slots = current.values.sort
      slots = (0...ids.size).map { |i| slots.first.to_i + i } if slots.uniq.size < slots.size
      model.transaction do
        ids.zip(slots).each { |id, position| model.where(id: id).update_all(position: position, updated_at: Time.current) }
      end
      SiteCache.bump! # update_all no dispara callbacks: el orden nuevo se ve en el sitio
      ActivityLog.record!(nil, "update", { "orden de #{model.model_name.human(count: 2).downcase}" => [nil, "#{ids.size} elementos"] })
      head :no_content
    end

    private

    def required_action = :read
  end
end
