module Admin
  class ActivityLogsController < BaseController
    self.permission_resource = :activity

    def index
      scope = ActivityLog.recent.includes(:user)
      scope = scope.where(user_id: User.unscoped.find_by(code: params[:user_id])&.id) if params[:user_id].present?
      scope = scope.where(action: params[:log_action]) if params[:log_action].present?
      scope = scope.where(subject_type: params[:subject_type]) if params[:subject_type].present?
      scope = scope.where(subject_type: params[:type], subject_id: subject_id_param) if params[:subject_id].present?
      @users = User.ordered
      @subject_types = ActivityLog.distinct.order(:subject_type).pluck(:subject_type).compact
      @logs = paginate(scope, per: 50)
    end

    def show
      @log = ActivityLog.find(params[:id])
    end

    private

    # «Ver todos los cambios» de un registro: llega su identificador amigable, no el id
    def subject_id_param
      model = params[:type].to_s.safe_constantize
      return unless model.is_a?(Class) && model < ApplicationRecord && ActivityLog.exists?(subject_type: model.name)
      model.unscoped.find(params[:subject_id]).id
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
