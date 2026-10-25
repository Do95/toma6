module Admin
  class TrashController < BaseController
    self.permission_resource = :trash

    def index
      @groups = SoftDeletable::MODELS.filter_map do |name|
        model = name.constantize
        next unless can?(model.permission_resource, :read)
        # Cada tipo tiene su propia paginación (?page_projects=2)
        records = paginate(model.trashed.includes(:deleter).order(deleted_at: :desc), per: 25, page_key: "page_#{model.model_name.plural}")
        [model, records, @pagy] if records.any?
      end
      @retention = settings.trash_retention_days
    end

    def restore
      record = find_trashed
      authorize!(record.class.permission_resource, :write)
      authorize!(:trash, :restore)
      record.restore!
      redirect_to admin_trash_path, notice: "Se restauró «#{record.display_name.truncate(60)}».", status: :see_other
    end

    def purge
      authorize!(:trash, :purge)
      record = find_trashed
      ActivityLog.record!(record, "purge", { "registro" => [record.display_name, nil] })
      record.destroy!
      redirect_to admin_trash_path, notice: "Se eliminó definitivamente.", status: :see_other
    end

    def empty
      authorize!(:trash, :purge)
      result = TrashPurger.call(everything: true)
      redirect_to admin_trash_path, notice: "Papelera vaciada: #{result.total} registros eliminados definitivamente.",
                                    status: :see_other
    end

    private

    def required_action = :read

    def find_trashed
      model = SoftDeletable::MODELS.include?(params[:type]) ? params[:type].constantize : raise(ActiveRecord::RecordNotFound)
      model.trashed.find(params[:id])
    end
  end
end
