module Admin
  # Eliminar definitivamente (sin pasar por la papelera). Borra también los archivos.
  # Solo quienes tienen permiso de "eliminar definitivamente" (por defecto, administradores).
  class DestroysController < BaseController
    def destroy
      model = SoftDeletable::MODELS.include?(params[:type]) ? params[:type].constantize : raise(ActiveRecord::RecordNotFound)
      record = model.unscoped.find(params[:id])
      authorize!(model.permission_resource, :purge)
      authorize!(:trash, :purge)

      if record.is_a?(User) && (record == current_user || (record.admin? && User.kept.where(role: "admin").where.not(id: record.id).none?))
        return redirect_back fallback_location: admin_users_path, alert: "No podés eliminar tu propia cuenta ni al último administrador."
      end

      label = record.display_name
      ActivityLog.record!(record, "purge", { "registro" => [label, nil] })
      record.destroy!
      redirect_to safe_return || admin_root_path, notice: "«#{label.truncate(60)}» se eliminó definitivamente.", status: :see_other
    end

    private

    def required_action = :read

    def safe_return
      path = params[:return_to].to_s
      path.start_with?("/admin") && !path.start_with?("//") ? path : nil
    end
  end
end
