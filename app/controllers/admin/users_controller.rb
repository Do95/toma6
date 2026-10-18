module Admin
  class UsersController < ResourceController
    self.resource_class = User
    self.permission_resource = :users

    def create
      @record = User.new(record_params)
      generated = nil
      if @record.password.blank?
        generated = SecureRandom.alphanumeric(14)
        @record.password = @record.password_confirmation = generated
      end
      if @record.save
        @record.send_reset_password_instructions if params[:send_invite] == "1"
        notice = "Se creó la cuenta de #{@record.name}."
        notice += " Contraseña temporal: #{generated}" if generated && params[:send_invite] != "1"
        redirect_to admin_users_path, notice: notice
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      attrs = record_params
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?
      if @record == current_user && attrs[:role].present? && attrs[:role] != "admin"
        return redirect_to edit_admin_user_path(@record), alert: "No podés quitarte el rol de administrador a vos mismo."
      end
      if @record.update(attrs)
        redirect_to admin_users_path, notice: "Cambios guardados en la cuenta de #{@record.name}."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @record == current_user
        return redirect_to admin_users_path, alert: "No podés eliminar tu propia cuenta."
      end
      if @record.admin? && User.kept.where(role: "admin").where.not(id: @record.id).none?
        return redirect_to admin_users_path, alert: "Tiene que quedar al menos un administrador."
      end
      super
    end

    private

    def collection = User.kept.ordered

    def record_params
      params.require(:user).permit(:name, :email, :role, :active, :avatar, :password, :password_confirmation)
    end
  end
end
