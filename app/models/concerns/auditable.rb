# Registra quién creó, modificó y eliminó cada registro, y guarda el historial
# completo de cambios en ActivityLog.
module Auditable
  extend ActiveSupport::Concern

  IGNORED_ATTRIBUTES = %w[id token slug_history updated_at created_at updated_by_id created_by_id deleted_by_id
                          encrypted_password reset_password_token remember_created_at
                          sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip
                          user_access_token page_access_token app_secret].freeze

  included do
    belongs_to :creator, class_name: "User", foreign_key: :created_by_id, optional: true
    belongs_to :updater, class_name: "User", foreign_key: :updated_by_id, optional: true

    before_create :assign_creator
    before_update :assign_updater

    after_create_commit :log_create
    after_update_commit :log_update

    has_many :activity_logs, -> { order(created_at: :desc) }, as: :subject, dependent: nil
  end

  class_methods do
    def audit_skip?(attribute) = IGNORED_ATTRIBUTES.include?(attribute.to_s)
  end

  # Cambios extra (por ejemplo, ítems de una cotización) que el modelo puede aportar.
  def audit_extra_changes = {}

  private

  def assign_creator
    return unless Current.user
    self.created_by_id ||= Current.user.id if has_attribute?(:created_by_id)
    self.updated_by_id ||= Current.user.id if has_attribute?(:updated_by_id)
  end

  def assign_updater
    return unless Current.user && has_attribute?(:updated_by_id)
    meaningful = changes.keys - IGNORED_ATTRIBUTES - %w[deleted_at]
    self.updated_by_id = Current.user.id if meaningful.any? || audit_extra_changes.any?
  end

  def log_create
    ActivityLog.record!(self, "create", audit_payload(saved_changes))
  end

  def log_update
    changes = saved_changes.dup
    if changes.key?("deleted_at") && respond_to?(:deleted_at)
      before, after = changes["deleted_at"]
      return ActivityLog.record!(self, "delete") if before.nil? && after.present?
      return ActivityLog.record!(self, "restore") if before.present? && after.nil?
    end

    payload = audit_payload(changes).merge(audit_extra_changes)
    ActivityLog.record!(self, "update", payload) if payload.any?
  end

  def audit_payload(changes)
    changes.reject { |attr, _| self.class.audit_skip?(attr) || attr == "deleted_at" }
           .transform_values { |(from, to)| [audit_format(from), audit_format(to)] }
  end

  def audit_format(value)
    case value
    when CarrierWave::Uploader::Base then value.file&.filename
    when BigDecimal then value.to_s("F")
    when Time, DateTime, ActiveSupport::TimeWithZone then value.iso8601
    else value
    end
  end
end
