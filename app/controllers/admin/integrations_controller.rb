module Admin
  # Conexión opcional con Meta. Al conectar una página se desbloquean las publicaciones.
  class IntegrationsController < BaseController
    self.permission_resource = :integrations

    before_action :load_integration

    def show
      @pages = session[:meta_pages]
    end

    def update
      attrs = params.require(:integration).permit(:app_id, :app_secret, :graph_version, :facebook_enabled, :instagram_enabled)
      attrs = attrs.except(:app_secret) if attrs[:app_secret].blank?
      if @integration.update(attrs)
        redirect_to admin_integration_path, notice: "Integración actualizada."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def destroy
      @integration.disconnect!
      session.delete(:meta_pages)
      redirect_to admin_integration_path, notice: "Se desconectó la página. Las publicaciones quedan bloqueadas hasta volver a conectar.",
                                          status: :see_other
    end

    def connect
      return redirect_to(admin_integration_path, alert: "Primero guardá el App ID y el App Secret.") unless @integration.app_configured?
      state = SecureRandom.hex(16)
      session[:meta_oauth_state] = state
      redirect_to Meta::Client.new(@integration).authorize_url(redirect_uri: callback_url, state: state),
                  allow_other_host: true
    end

    def callback
      if params[:error].present?
        return redirect_to admin_integration_path, alert: "Meta canceló la conexión: #{params[:error_description] || params[:error]}"
      end
      expected = session.delete(:meta_oauth_state)
      unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, params[:state].to_s)
        return redirect_to admin_integration_path, alert: "La sesión de conexión venció. Probá de nuevo."
      end

      client = Meta::Client.new(@integration)
      token = client.exchange_code(params[:code], redirect_uri: callback_url)
      @integration.update!(user_access_token: token[:token], user_token_expires_at: token[:expires_at], last_error: nil)
      pages = client.pages(token[:token])
      if pages.empty?
        return redirect_to admin_integration_path, alert: "Tu cuenta no administra ninguna página de Facebook."
      end
      session[:meta_pages] = pages.map { |p| p.except(:token) }
      redirect_to admin_integration_path, notice: "Cuenta conectada. Elegí la página que vas a usar."
    rescue Meta::Error => e
      @integration.update_columns(last_error: e.message)
      redirect_to admin_integration_path, alert: e.message
    end

    def select_page
      client = Meta::Client.new(@integration)
      page = client.pages.find { |p| p[:id] == params[:page_id] }
      return redirect_to(admin_integration_path, alert: "No encontramos esa página en tu cuenta.") unless page

      @integration.update!(
        page_id: page[:id], page_name: page[:name], page_access_token: page[:token],
        instagram_account_id: page[:ig_id], instagram_username: page[:ig_username],
        facebook_enabled: true, instagram_enabled: page[:ig_id].present?,
        connected_at: Time.current, connected_by: current_user, last_error: nil
      )
      session.delete(:meta_pages)
      msg = "Listo: #{page[:name]} conectada."
      msg += " Instagram @#{page[:ig_username]} también quedó vinculado." if page[:ig_id]
      redirect_to admin_integration_path, notice: msg
    rescue Meta::Error => e
      redirect_to admin_integration_path, alert: e.message
    end

    private

    def load_integration
      @integration = Integration.meta!
    end

    def callback_url = callback_admin_integration_url

    def required_action = %w[show].include?(action_name) ? :read : :write
  end
end
