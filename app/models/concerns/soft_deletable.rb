# Eliminación lógica: los registros van a la papelera (deleted_at) y se pueden
# restaurar. La tarea PurgeTrashJob los borra definitivamente pasados los días
# configurados en Ajustes.
module SoftDeletable
  extend ActiveSupport::Concern

  # Orden de purga: primero los hijos, después los padres.
  MODELS = %w[SectionBlock Section MediaItem Album Project ServiceOption Service Category Faq ProcessStep AboutValue
              SocialPost ShortLink Quote QuoteRequest User].freeze

  included do
    belongs_to :deleter, class_name: "User", foreign_key: :deleted_by_id, optional: true

    scope :kept, -> { where(deleted_at: nil) }
    scope :trashed, -> { where.not(deleted_at: nil) }

    class_attribute :soft_delete_cascades, default: []
  end

  class_methods do
    # Asociaciones que se envían a la papelera junto con el registro.
    def soft_delete_cascade(*associations)
      self.soft_delete_cascades = soft_delete_cascades + associations
    end

    def trash_models
      SoftDeletable::MODELS.map(&:constantize)
    end
  end

  def trashed? = deleted_at.present?
  def kept? = !trashed?

  def soft_delete!(at: Time.current)
    transaction do
      update_columns_for_trash(at)
      soft_delete_cascades.each do |assoc|
        public_send(assoc).kept.find_each { |child| child.soft_delete!(at: at) }
      end
    end
  end

  def restore!
    stamp = deleted_at
    transaction do
      self.deleted_at = nil
      self.deleted_by_id = nil
      save!(validate: false)
      soft_delete_cascades.each do |assoc|
        public_send(assoc).trashed.where(deleted_at: stamp).find_each(&:restore!)
      end
    end
  end

  def purge_on
    days = SiteSetting.current.trash_retention_days
    deleted_at && (deleted_at + days.days).to_date
  end

  private

  def update_columns_for_trash(at)
    self.deleted_at = at
    self.deleted_by_id = Current.user&.id
    save!(validate: false)
  end
end
