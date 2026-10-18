class ApplicationController < ActionController::Base
  before_action :set_request_context
  layout :layout_by_resource

  helper_method :settings

  def settings = SiteSetting.current

  protected

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || admin_root_path
  end

  def after_sign_out_path_for(_scope) = new_user_session_path

  private

  def set_request_context
    Current.ip_address = request.remote_ip
  end

  def layout_by_resource
    devise_controller? ? "auth" : nil
  end
end
