module Admin
  # Agregar y quitar fotos de una galería (sin borrarlas de la biblioteca).
  class MediaPlacementsController < BaseController
    self.permission_resource = :content

    def create
      gallery = MediaPlacement.gallery_from_key(params[:gallery])
      return redirect_back(fallback_location: admin_media_items_path, alert: "Galería no encontrada.") unless gallery
      items = MediaItem.kept.where(id: Array(params[:ids]).map(&:to_i))
      added = items.count { |m| !m.in_gallery?(gallery) }
      items.each { |m| MediaPlacement.attach!(m, gallery) }
      ActivityLog.record!(gallery, "attach", { "fotos" => [nil, added.to_s] }) if added.positive?
      redirect_to gallery_path_for(gallery), notice: added.positive? ? "Se agregaron #{added} #{added == 1 ? 'foto' : 'fotos'} a la galería." : "Esas fotos ya estaban en la galería."
    end

    def destroy
      placement = MediaPlacement.find(params[:id])
      gallery = placement.gallery
      placement.destroy!
      respond_to do |format|
        format.html { redirect_back fallback_location: gallery_path_for(gallery), notice: "Se quitó de la galería. La foto sigue en la biblioteca.", status: :see_other }
        format.json { head :no_content }
      end
    end

    # Usar una foto como portada del álbum
    def cover
      placement = MediaPlacement.find(params[:id])
      album = placement.album or return redirect_back(fallback_location: admin_media_items_path, alert: "Solo los álbumes tienen portada.")
      album.update!(cover_media_item: placement.media_item)
      redirect_back fallback_location: edit_admin_album_path(album), notice: "Nueva portada de «#{album.title}».", status: :see_other
    end

    private

    def gallery_path_for(gallery)
      gallery.is_a?(Album) ? edit_admin_album_path(gallery) : edit_admin_project_path(gallery, tab: "galeria")
    end

    def required_action = :write
  end
end
