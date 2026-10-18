module Admin
  # Cada persona edita su propio nombre, foto y contraseña.
  class ProfilesController < BaseController
    skip_before_action :authorize_section!

    def edit
      @user = current_user
    end

    def update
      @user = current_user
      attrs = params.require(:user).permit(:name, :email, :avatar, :remove_avatar, :password, :password_confirmation, :current_password)
      changing_password = attrs[:password].present?

      saved = if changing_password || attrs[:email] != @user.email
                @user.update_with_password(attrs)
              else
                @user.update(attrs.except(:password, :password_confirmation, :current_password))
              end

      if saved
        bypass_sign_in(@user) if changing_password
        redirect_to edit_admin_profile_path, notice: "Tu perfil se actualizó."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
