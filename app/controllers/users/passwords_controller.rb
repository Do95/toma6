# Crear contraseña desde el correo: sirve tanto para recuperar la contraseña
# como para aceptar una invitación al panel.
module Users
  class PasswordsController < Devise::PasswordsController
    before_action :load_invitation, only: %i[edit update]

    def update
      super do |user|
        if user.errors.empty? && user.invitation_pending?
          user.accept_invitation!
          @accepted = true
        end
      end
      flash[:notice] = "¡Listo, #{resource.name.to_s.split.first}! Tu cuenta ya está activa. Te damos la bienvenida." if @accepted
    end

    private

    # Si el enlace es de una invitación pendiente, la pantalla le da la bienvenida
    def load_invitation
      token = params[:reset_password_token] || params.dig(:user, :reset_password_token)
      user = User.with_reset_password_token(token) if token.present?
      @invited = user if user&.invitation_pending?
    end
  end
end
