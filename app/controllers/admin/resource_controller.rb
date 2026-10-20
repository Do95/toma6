# CRUD genérico para las secciones simples del panel. Cada controlador define
# resource_class, los parámetros permitidos y, si quiere, su propio índice.
module Admin
  class ResourceController < BaseController
    self.permission_resource = :content
    class_attribute :resource_class
    class_attribute :sortable, default: false

    # Toda acción con :id (incluidas pdf, share, convert, etc.) carga el registro
    before_action :load_record, if: -> { params.key?(:id) }

    helper_method :resource_class, :sortable?, :collection_path, :record_path, :new_record_path

    def index
      @records = paginate(collection, per: per_page)
    end

    def show
      redirect_to edit_record_path(@record)
    end

    def new
      @record = resource_class.new(new_record_defaults)
    end

    def create
      @record = resource_class.new(record_params)
      if @record.save
        redirect_to after_save_path, notice: "Listo, se creó «#{@record.display_name.truncate(60)}»."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @record.update(record_params)
        redirect_to after_save_path, notice: "Cambios guardados en «#{@record.display_name.truncate(60)}»."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @record.soft_delete!
      redirect_to safe_return_to || collection_path, notice: trash_notice(@record), status: :see_other
    end

    # Acción rápida de las listas: mostrar / ocultar en el sitio sin entrar a editar
    def toggle
      return head(:not_found) unless @record.respond_to?(:published?)
      @record.update!(published: !@record.published?)
      name = @record.display_name.truncate(50)
      notice = @record.published? ? "«#{name}» ahora se ve en el sitio." : "«#{name}» quedó oculto: ya no se ve en el sitio."
      redirect_to safe_return_to || collection_path, notice: notice, status: :see_other
    end

    private

    def collection
      scope = resource_class.kept
      scope = scope.ordered if resource_class.respond_to?(:ordered)
      scope = scope.includes(:updater) if resource_class.reflect_on_association(:updater)
      scope
    end

    def per_page = sortable? ? 200 : 30
    def sortable? = sortable

    def load_record
      scope = resource_class.kept
      @record = resource_class.respond_to?(:friendly) ? scope.friendly.find(params[:id]) : scope.find(params[:id])
    end

    def new_record_defaults = {}

    # Volver a la lista desde donde se usó la acción rápida (con sus filtros y página)
    def safe_return_to
      path = params[:return_to].to_s
      path if path.start_with?("/admin") && !path.start_with?("//")
    end
    def record_params = raise(NotImplementedError)
    def param_key = resource_class.model_name.param_key

    def after_save_path = collection_path
    def collection_path = polymorphic_path([:admin, resource_class])
    def record_path(record) = polymorphic_path([:admin, record])
    def edit_record_path(record) = edit_polymorphic_path([:admin, record])
    def new_record_path = new_polymorphic_path([:admin, resource_class])
  end
end
