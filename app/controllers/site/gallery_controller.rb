module Site
  class GalleryController < BaseController
    def index
      return if page_cached?
      items = MediaItem.visible.in_gallery.includes(:category, placements: [{ album: :project }, :project]).ordered.to_a
      # Se muestra si no está en ninguna galería o si al menos una de sus galerías es visible
      @media = items.select { |m| m.placements.empty? || m.placements.any? { |p| gallery_visible?(p) } }
      @categories = Category.kept.ordered.select { |c| @media.any? { |m| m.category_id == c.id } }
      @albums = Album.visible.in_gallery.includes(:project, placements: :media_item).ordered
                     .select { |a| a.visible_media.any? && (a.project.nil? || a.project.visible?) }
      @projects = @media.flat_map { |m| visible_projects(m) }.uniq.sort_by(&:position)
    end

    def album
      @album = Album.visible.includes(:project).friendly.find(params[:slug])
      return redirect_to(album_path(@album.slug), status: :moved_permanently) if params[:slug] != @album.slug
      raise ActiveRecord::RecordNotFound if @album.project && !@album.project.visible?
      return if page_cached?(@album.slug)
      @album = Album.includes(:project, placements: { media_item: [:category, { placements: [:album, :project] }] }).find(@album.id)
      @media = @album.visible_media
      @siblings = @album.project ? @album.project.albums.select { |a| a.published? && a.id != @album.id } : []
    end

    private

    def gallery_visible?(placement)
      if placement.album
        placement.album.visible? && (placement.album.project.nil? || placement.album.project.visible?)
      else
        placement.project&.visible?
      end
    end

    def visible_projects(item)
      item.placements.filter_map { |p| p.album ? p.album.project : p.project }.select(&:visible?)
    end
  end
end
