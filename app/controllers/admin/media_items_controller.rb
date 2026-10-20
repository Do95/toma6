module Admin
  # Biblioteca de fotos y videos. Una foto vive una sola vez acá y se ubica en
  # todas las galerías que quieras (álbumes o galerías generales de proyectos).
  class MediaItemsController < ResourceController
    self.resource_class = MediaItem

    before_action :load_gallery, only: %i[index new create bulk_create library]

    def index
      @categories = Category.kept.ordered
      @gallery_options = MediaPlacement.gallery_options
      @records = paginate(filtered_collection, per: 48)
    end

    def new
      @record = MediaItem.new(kind: params[:kind].presence || "photo")
    end

    def create
      @record = MediaItem.new(record_params)
      if @record.save
        sync_galleries(@record, gallery_keys_param)
        MediaPlacement.attach!(@record, @gallery) if @gallery
        redirect_to after_save_path, notice: "Listo, se agregó «#{@record.display_name}»."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @record.update(record_params)
        sync_galleries(@record, gallery_keys_param) if params.key?(:gallery_keys) || params[:galleries_submitted]
        redirect_to after_save_path, notice: "Cambios guardados en «#{@record.display_name}»."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Subida múltiple. Si la foto ya estaba en la biblioteca (misma huella), no
    # se duplica: se reutiliza y se agrega a la galería.
    def bulk_create
      created = []
      reused = []
      errors = []
      bulk_video(created, errors) if params[:video_key].present? || params[:video].present?
      Array(params[:files]).compact_blank.each do |file|
        if (existing = MediaItem.find_duplicate(file))
          MediaPlacement.attach!(existing, @gallery) if @gallery
          reused << existing
          next
        end
        item = MediaItem.new(bulk_attributes.merge(kind: "photo", image: file))
        if item.save
          MediaPlacement.attach!(item, @gallery) if @gallery
          created << item
        else
          errors << "#{file.original_filename}: #{item.errors.full_messages.to_sentence}"
        end
      end

      respond_to do |format|
        format.json do
          render json: { created: created.size, reused: reused.size, errors: errors },
                 status: errors.any? && created.empty? && reused.empty? ? :unprocessable_entity : :ok
        end
        format.html do
          flash[:notice] = upload_notice(created.size, reused.size) if created.any? || reused.any?
          flash[:alert] = errors.to_sentence if errors.any?
          redirect_back fallback_location: admin_media_items_path
        end
      end
    end

    # Elegir fotos que ya están en la biblioteca para sumarlas a una galería.
    def library
      return redirect_to(admin_media_items_path, alert: "Elegí a qué galería agregar.") unless @gallery
      @categories = Category.kept.ordered
      scope = MediaItem.kept.includes(:category, placements: [:album, :project]).order(created_at: :desc)
      scope = scope.where(kind: params[:kind]) if MediaItem::KINDS.key?(params[:kind])
      scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
      scope = scope.where("media_items.title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      scope = scope.unplaced if params[:only] == "unplaced"
      @already = MediaPlacement.for_gallery(@gallery).pluck(:media_item_id).to_set
      @records = paginate(scope, per: 60)
    end

    # Acciones en lote desde la biblioteca
    def bulk_update
      ids = Array(params[:ids]).map(&:to_i)
      items = MediaItem.kept.where(id: ids)
      return redirect_back(fallback_location: admin_media_items_path, alert: "Seleccioná al menos un medio.") if items.empty?

      target = MediaPlacement.gallery_from_key(params[:target_gallery])
      msg = case params[:bulk_action]
            when "attach"
              return redirect_back(fallback_location: admin_media_items_path, alert: "Elegí la galería.") unless target
              items.each { |m| MediaPlacement.attach!(m, target) }
              ActivityLog.record!(target, "attach", { "fotos" => [nil, items.size.to_s] })
              "#{items.size} medios agregados a «#{target_label(target)}» (siguen en sus otras galerías)."
            when "detach"
              return redirect_back(fallback_location: admin_media_items_path, alert: "Elegí la galería.") unless target
              n = MediaPlacement.for_gallery(target).where(media_item_id: items.map(&:id)).destroy_all.size
              "#{n} medios quitados de «#{target_label(target)}». Siguen en la biblioteca."
            when "trash"
              authorize!(:content, :delete)
              items.each(&:soft_delete!)
              "#{items.size} medios enviados a la papelera."
            when "purge"
              authorize!(:content, :purge)
              items.each { |m| ActivityLog.record!(m, "purge", { "registro" => [m.display_name, nil] }); m.destroy! }
              "#{items.size} medios eliminados definitivamente."
            when "publish", "unpublish"
              items.each { |m| m.update(published: params[:bulk_action] == "publish") }
              "#{items.size} medios actualizados."
            when "gallery_on", "gallery_off"
              items.each { |m| m.update(show_in_gallery: params[:bulk_action] == "gallery_on") }
              "#{items.size} medios actualizados."
            when "categorize"
              items.each { |m| m.update(category_id: params[:target_category_id].presence) }
              "#{items.size} medios recategorizados."
            else
              "Elegí una acción."
            end
      redirect_back fallback_location: admin_media_items_path, notice: msg, status: :see_other
    end

    def share
      redirect_to new_admin_social_post_path(media_item_id: @record.id)
    end

    private

    def load_gallery
      @gallery = if params[:album_id].present?
                   Album.kept.friendly.find(params[:album_id])
                 elsif params[:project_id].present? && params[:project_id] != "none"
                   Project.kept.friendly.find(params[:project_id])
                 end
    end

    def filtered_collection
      scope = MediaItem.kept.includes(:category, :updater, placements: [:album, :project]).order(created_at: :desc)
      scope = scope.where(kind: params[:kind]) if MediaItem::KINDS.key?(params[:kind])
      scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
      if (g = MediaPlacement.gallery_from_key(params[:gallery]))
        scope = scope.where(id: MediaPlacement.for_gallery(g).select(:media_item_id))
      elsif params[:gallery] == "none"
        scope = scope.unplaced
      end
      scope = scope.where(show_in_gallery: true) if params[:in_gallery] == "1"
      scope = scope.where("media_items.title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      scope
    end

    # Ubica la foto exactamente en las galerías marcadas
    def sync_galleries(item, keys)
      return if keys.nil?
      wanted = keys.filter_map { |k| MediaPlacement.gallery_from_key(k) }
      wanted_keys = wanted.map { |g| MediaPlacement.gallery_key(g) }
      item.placements.includes(:album, :project).each do |p|
        p.destroy unless wanted_keys.include?(MediaPlacement.gallery_key(p.gallery))
      end
      wanted.each { |g| MediaPlacement.attach!(item, g) }
    end

    def gallery_keys_param
      return nil unless params.key?(:gallery_keys) || params[:galleries_submitted]
      Array(params[:gallery_keys]).compact_blank
    end

    def bulk_attributes
      attrs = params.permit(:category_id, :show_in_gallery).to_h.compact_blank
      attrs[:show_in_gallery] = attrs.fetch(:show_in_gallery, "1") == "1"
      attrs
    end

    # Un video del recuadro de subida: llega ya en S3 (video_key) o, sin S3, como archivo.
    # La portada la genera el navegador con un cuadro del video.
    def bulk_video(created, errors)
      name = params[:video_name].presence || params[:video]&.original_filename || "Video"
      item = MediaItem.new(bulk_attributes.merge(kind: "video", image: params[:poster], duration: params[:duration].presence,
                                                 title: File.basename(name.to_s, ".*").tr("-_", "  ").squish.capitalize))
      if params[:video_key].present? then item.video_direct_key = params[:video_key] else item.video = params[:video] end
      if item.save
        MediaPlacement.attach!(item, @gallery) if @gallery
        created << item
      else
        errors << "#{name}: #{item.errors.full_messages.to_sentence}"
      end
    end

    def upload_notice(created, reused)
      parts = []
      parts << "#{created} #{created == 1 ? 'archivo subido' : 'archivos subidos'}" if created.positive?
      parts << "#{reused} ya #{reused == 1 ? 'estaba' : 'estaban'} en la biblioteca y se #{reused == 1 ? 'agregó' : 'agregaron'} sin duplicar" if reused.positive?
      parts.join(" · ") + "."
    end

    def target_label(gallery) = gallery.is_a?(Album) ? gallery.display_name : "#{gallery.title} · General"

    def after_save_path
      return safe_return_path if safe_return_path
      return edit_admin_album_path(@gallery) if @gallery.is_a?(Album)
      return edit_admin_project_path(@gallery) if @gallery.is_a?(Project)
      admin_media_items_path
    end

    def safe_return_path
      path = params[:return_to].to_s
      path.start_with?("/admin/") && !path.start_with?("//") ? path : nil
    end

    def record_params
      params.require(:media_item).permit(
        :kind, :title, :description, :image, :remove_image, :video, :video_direct_key, :remove_video, :duration,
        :category_id, :show_in_gallery, :featured, :published
      )
    end
  end
end
