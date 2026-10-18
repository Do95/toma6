module Admin
  # Guarda el orden después de arrastrar elementos en una lista.
  class SortingsController < BaseController
    MODELS = {
      "sections" => Section, "services" => Service, "service_options" => ServiceOption, "projects" => Project, "albums" => Album,
      "media_items" => MediaItem, "media_placements" => MediaPlacement, "categories" => Category, "faqs" => Faq, "process_steps" => ProcessStep,
      "about_values" => AboutValue
    }.freeze

    def update
      model = MODELS.fetch(params[:model]) { return head(:unprocessable_entity) }
      authorize!(model.permission_resource, :write)
      ids = Array(params[:ids]).map(&:to_i)
      model.transaction do
        ids.each_with_index { |id, index| model.where(id: id).update_all(position: index + 1, updated_at: Time.current) }
      end
      ActivityLog.record!(nil, "update", { "orden de #{model.model_name.human(count: 2).downcase}" => [nil, "#{ids.size} elementos"] })
      head :no_content
    end

    private

    def required_action = :read
  end
end
