module Admin
  class BaseController < ApplicationController
    class NotAuthorized < StandardError; end

    include Paginates

    layout "admin"

    class_attribute :permission_resource, default: :dashboard

    before_action :authenticate_user!
    before_action :set_current_user
    before_action :authorize_section!

    helper_method :can?, :social_unlocked?, :pending_requests_count, :failed_emails_count

    rescue_from NotAuthorized do
      message = "Tu rol (#{current_user.role_label}) no tiene permiso para esa acción."
      respond_to do |format|
        format.html { redirect_back fallback_location: admin_root_path, alert: message }
        format.json { render json: { error: message }, status: :forbidden }
        format.any { head :forbidden }
      end
    end

    private

    def set_current_user
      Current.user = current_user
    end

    def can?(resource, action = :read) = current_user&.can?(resource, action)

    def authorize!(resource, action = :read)
      raise NotAuthorized unless can?(resource, action)
    end

    def authorize_section!
      authorize!(permission_resource, required_action)
    end

    def required_action
      case action_name
      when "index", "show", "pdf", "share" then :read
      when "destroy" then :delete
      else :write
      end
    end

    def social_unlocked? = Integration.social_unlocked?

    def pending_requests_count
      @pending_requests_count ||= QuoteRequest.pending.count
    end

    def failed_emails_count
      @failed_emails_count ||= can?(:sales) ? EmailLog.failed.count : 0
    end

    def trash_notice(record)
      days = settings.trash_retention_days
      "«#{record.display_name.truncate(50)}» se envió a la papelera. Podés restaurarlo durante #{days} días."
    end
  end
end
