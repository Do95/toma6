module Site
  class ProjectsController < BaseController
    def index
      return if page_cached?
      @projects = Project.visible.ordered.includes(albums: { placements: :media_item }, general_placements: :media_item)
      @categories = @projects.map(&:category_label).compact_blank.uniq
    end

    def show
      @project = Project.visible.friendly.find(params[:slug])
      # URL vieja (el título cambió): redirige a la actual sin perder posicionamiento
      return redirect_to(project_path(@project.slug), status: :moved_permanently) if params[:slug] != @project.slug
      return if page_cached?(@project.slug)
      @project = Project.includes(:services, albums: { placements: { media_item: [:category, { placements: [:album, :project] }] } },
                                  general_placements: { media_item: [:category, { placements: [:album, :project] }] }).find(@project.id)
      @albums = @project.albums.select { |a| a.published? && a.visible_media.any? }
      @loose = @project.loose_media
      # Galería general + álbumes publicados, sin repetir (una foto puede estar en varios)
      @all_media = (@loose + @albums.flat_map(&:visible_media)).uniq
      # Para las pestañas: en qué galerías de este proyecto está cada foto
      @tokens = Hash.new { |h, k| h[k] = [] }
      @loose.each { |m| @tokens[m.id] << "__general" }
      @albums.each { |a| a.visible_media.each { |m| @tokens[m.id] << a.slug } }
      @prev_project, @next_project = @project.neighbors
      @sections = @project.page_sections.select(&:published?)
    end
  end
end
