module Admin
  class ServicesController < ResourceController
    self.resource_class = Service
    self.sortable = true

    def new
      @record = Service.new(visual_style: "image", quotable: true, price_prefix: "Desde")
      @record.options.build(kind: "addon")
    end

    # Mostrar / ocultar desde la lista, sin entrar a editar
    def toggle
      authorize!(:content, :write)
      @record.update!(published: !@record.published?)
      notice = @record.published? ? "«#{@record.title}» se ve en el sitio y en el cotizador." : "«#{@record.title}» quedó oculto: no aparece en el sitio ni en el cotizador."
      redirect_back fallback_location: admin_services_path, notice: notice, status: :see_other
    end

    private

    def collection = super.includes(:options, :image_media_item)

    def after_save_path = edit_admin_service_path(@record)

    def record_params
      params.require(:service).permit(
        :title, :slug, :summary, :description, :tags, :visual_style,
        :image, :image_secondary, :image_tertiary, :remove_image, :remove_image_secondary, :remove_image_tertiary,
        :image_media_item_id, :image_secondary_media_item_id, :image_tertiary_media_item_id,
        :quotable, :base_price, :price_prefix, :price_unit, :published,
        options_attributes: %i[id name description kind group_name price unit_label min_quantity max_quantity
                               default_selected published position remove]
      )
    end
  end
end
