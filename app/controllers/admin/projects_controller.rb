module Admin
  class ProjectsController < ResourceController
    self.resource_class = Project
    self.sortable = true

    def edit
      @albums = @record.albums.includes(placements: :media_item)
      @general_placements = general_placements
    end

    def update
      if @record.update(record_params)
        redirect_to edit_admin_project_path(@record, tab: "datos"), notice: "Cambios guardados en «#{@record.title}»."
      else
        @albums = @record.albums
        @general_placements = general_placements
        params[:tab] = "datos"
        render :edit, status: :unprocessable_entity
      end
    end

    # Atajo: crear una publicación para redes a partir del proyecto.
    def share
      redirect_to new_admin_social_post_path(project_id: @record.id)
    end

    private

    def collection
      scope = super.includes(:albums)
      scope = scope.where("projects.title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      scope
    end

    def general_placements
      @record.general_placements.includes(media_item: [:category, :placements]).select { |p| p.media_item&.kept? }
    end

    def after_save_path = edit_admin_project_path(@record)

    def record_params
      params.require(:project).permit(
        :title, :slug, :category_label, :client_name, :location, :event_date, :summary, :body,
        :cover, :remove_cover, :video, :remove_video, :video_link, :featured, :published, service_ids: []
      )
    end
  end
end
