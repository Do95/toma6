class ActivityLog < ApplicationRecord
  ACTIONS = {
    "create" => "Creó",
    "update" => "Modificó",
    "delete" => "Envió a la papelera",
    "restore" => "Restauró",
    "purge" => "Eliminó definitivamente",
    "sign_in" => "Inició sesión",
    "publish" => "Publicó",
    "send" => "Envió",
    "convert" => "Convirtió",
    "attach" => "Agregó a galería",
    "detach" => "Quitó de galería"
  }.freeze

  belongs_to :user, optional: true
  belongs_to :subject, polymorphic: true, optional: true

  scope :recent, -> { order(created_at: :desc) }

  def self.record!(subject, action, changeset = {})
    create!(
      user: Current.user,
      user_name: Current.user&.name || "Sistema",
      action: action,
      subject_type: subject&.class&.base_class&.name,
      subject_id: subject&.id,
      subject_label: subject&.display_name&.truncate(120),
      changeset: changeset.presence || {},
      ip_address: Current.ip_address,
      created_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error("[ActivityLog] #{e.class}: #{e.message}")
    nil
  end

  def action_label = ACTIONS.fetch(action, action.humanize)

  def subject_model_name
    subject_type&.safe_constantize&.model_name&.human || subject_type
  end
end
