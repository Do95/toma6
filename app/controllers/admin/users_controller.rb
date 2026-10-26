module Admin
  class UsersController < ResourceController
    self.resource_class = User
    self.permission_resource = :users

    # Al super admin solo lo puede tocar él mismo
    before_action :protect_super_admin, only: %i[edit update destroy invite]

    def create
      @record = User.new(record_params)
      invite = params[:send_invite] == "1"
      generated = nil
      if @record.password.blank?
        # Con invitación, la persona crea la suya: esta no se muestra ni se usa
        generated = SecureRandom.alphanumeric(invite ? 32 : 14)
        @record.password = @record.password_confirmation = generated
      end
      if @record.save
        if invite
          @record.invite!(by: current_user)
          notice = "¡Listo! Le enviamos la invitación a #{@record.email}. Tiene #{User::INVITATION_VALID_FOR.in_days.to_i} días para aceptarla."
        else
          notice = "Se creó la cuenta de #{@record.name}."
          notice += " Contraseña temporal: #{generated}" if generated
        end
        redirect_to admin_users_path, notice: notice
      else
        render :new, status: :unprocessable_entity
      end
    end

    # Reenviar la invitación (genera un enlace nuevo y anula el anterior)
    def invite
      return redirect_to(edit_admin_user_path(@record), alert: "#{@record.name} ya creó su contraseña.") unless @record.invitation_pending?
      @record.invite!(by: current_user)
      redirect_back fallback_location: admin_users_path, notice: "Le enviamos una invitación nueva a #{@record.email}. La anterior ya no sirve."
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
      if @record.super_admin?
        return redirect_to admin_users_path, alert: "El super admin no se puede eliminar."
      end
      if @record == current_user
        return redirect_to admin_users_path, alert: "No podés eliminar tu propia cuenta."
      end
      if @record.admin? && User.kept.where(role: "admin").where.not(id: @record.id).none?
        return redirect_to admin_users_path, alert: "Tiene que quedar al menos un administrador."
      end
      super
    end

    private

    def protect_super_admin
      return unless @record.super_admin? && @record != current_user
      redirect_to admin_users_path, alert: "Solo el super admin puede modificar su propia cuenta."
    end

    def collection = User.kept.ordered.includes(:invited_by)

    def record_params
      params.require(:user).permit(:name, :email, :code, :role, :active, :avatar, :password, :password_confirmation)
    end
  end
end
