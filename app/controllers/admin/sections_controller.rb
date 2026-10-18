module Admin
  # Secciones del inicio y de cada proyecto.
  class SectionsController < ResourceController
    self.resource_class = Section
    self.sortable = true

    before_action :load_project, only: %i[index new create restore_defaults]

    def index
      Section.ensure_home_defaults!(settings) unless @project
      @records = scope_for(@project).includes(:updater, :album).ordered
    end

    def new
      kind = params[:kind].presence
      page = @project ? "project" : "home"
      return render(:picker) unless kind && Section.addable_kinds(page).key?(kind)
      return redirect_to(admin_sections_path, alert: "Solo un administrador puede agregar código embebido.") if kind == "embed" && !can?(:settings, :write)
      @record = Section.new(page: page, project: @project, kind: kind, theme: kind == "cta" ? "red" : "dark",
                            title: Section::KINDS.dig(kind, :label))
      build_example_blocks if kind == "custom"
    end

    def create
      @record = Section.new(record_params.merge(page: @project ? "project" : "home", project: @project))
      authorize!(:settings, :write) if @record.kind == "embed"
      @record.position = (scope_for(@project).maximum(:position) || 0) + 1
      if @record.save
        redirect_to after_save_path, notice: "Sección «#{@record.display_name}» agregada al final. Arrastrala para ubicarla."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize!(:settings, :write) if @record.kind == "embed"
      if @record.update(record_params)
        redirect_to after_save_path, notice: "Sección «#{@record.display_name}» actualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Vuelve a crear las secciones fijas que falten
    def restore_defaults
      authorize!(:content, :write)
      created = @project ? Section.restore_project_defaults!(@project) : Section.restore_home_defaults!(settings)
      notice = created.any? ? "Se agregaron #{created.size} secciones fijas: #{created.map(&:kind_label).to_sentence}." : "No faltaba ninguna sección fija."
      redirect_to(@project ? edit_admin_project_path(@project, tab: "secciones") : admin_sections_path, notice: notice)
    end

    def duplicate
      authorize!(:content, :write)
      return redirect_to(after_save_path, alert: "Las secciones fijas no se pueden duplicar.") if @record.builtin?
      copy = @record.duplicate!
      redirect_to edit_admin_section_path(copy), notice: "Sección duplicada. Editá la copia."
    end

    def toggle
      authorize!(:content, :write)
      @record.update!(published: !@record.published?)
      redirect_back fallback_location: after_save_path, notice: @record.published? ? "Sección visible." : "Sección oculta.", status: :see_other
    end

    private

    def load_project
      @project = Project.kept.friendly.find(params[:project_id]) if params[:project_id].present?
    end

    def build_example_blocks
      [["camara", "Primera idea"], ["dron", "Segunda idea"], ["calendario", "Tercera idea"]].each_with_index do |(ill, title), i|
        @record.blocks.build(illustration: ill, title: title, body: "Contá en una o dos líneas por qué importa.", position: i + 1)
      end
    end

    def scope_for(project) = project ? Section.kept.for_project(project) : Section.kept.home

    def collection_path = admin_sections_path

    def after_save_path
      project = @record&.project || @project
      project ? edit_admin_project_path(project, tab: "secciones") : admin_sections_path
    end

    def record_params
      params.require(:section).permit(
        :kind, :eyebrow, :title, :lead, :body, :note, :items, :image, :remove_image, :image_side,
        :video, :remove_video, :video_link, :button_label, :button_url, :secondary_label, :secondary_url,
        :theme, :album_id, :show_in_nav, :nav_label, :anchor, :published,
        :illustration, :layout, :align, :block_style, :embed_code, :embed_height,
        blocks_attributes: %i[id illustration image remove_image eyebrow title body button_label button_url position remove]
      )
    end
  end
end
