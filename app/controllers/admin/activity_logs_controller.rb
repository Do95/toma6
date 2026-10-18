module Admin
  class ActivityLogsController < BaseController
    self.permission_resource = :activity

    def index
      scope = ActivityLog.recent.includes(:user)
      scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
      scope = scope.where(action: params[:log_action]) if params[:log_action].present?
      scope = scope.where(subject_type: params[:subject_type]) if params[:subject_type].present?
      scope = scope.where(subject_type: params[:type], subject_id: params[:subject_id]) if params[:subject_id].present?
      @users = User.ordered
      @subject_types = ActivityLog.distinct.order(:subject_type).pluck(:subject_type).compact
      @logs = paginate(scope, per: 50)
    end

    def show
      @log = ActivityLog.find(params[:id])
    end
  end
end
