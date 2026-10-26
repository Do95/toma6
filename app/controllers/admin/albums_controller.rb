module Admin
  class AlbumsController < ResourceController
    self.resource_class = Album
    self.sortable = true

    def new
      @record = Album.new(project: (Project.kept.friendly.find(params[:project_id]) if params[:project_id].present?))
    end

    def edit
      @placements = live_placements
    end

    def update
      if @record.update(record_params)
        redirect_to edit_admin_album_path(@record), notice: "Cambios guardados en «#{@record.title}»."
      else
        @placements = live_placements
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def collection
      scope = super.includes(:project, placements: :media_item)
      if params[:project_id] == "none"
        scope = scope.where(project_id: nil)
      elsif params[:project_id].present?
        scope = scope.joins(:project).where(projects: { slug: params[:project_id] })
      end
      scope
    end

    def live_placements
      @record.placements.includes(media_item: [:category, :placements]).select { |p| p.media_item&.kept? }
    end

    def after_save_path = edit_admin_album_path(@record)

    def record_params
      params.require(:album).permit(:title, :slug, :description, :project_id, :cover, :remove_cover,
                                    :show_in_gallery, :published)
    end
  end
end
