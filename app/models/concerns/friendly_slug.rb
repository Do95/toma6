# Slugs amigables con friendly_id:
#   - "Quinceaños de Sofía" → quinceanos-de-sofia (y quinceanos-de-sofia-2 si se repite)
#   - si cambia el título, cambia el slug y la URL vieja sigue funcionando (historial)
#   - el slug también se puede escribir a mano desde el panel
module FriendlySlug
  extend ActiveSupport::Concern

  included do
    extend FriendlyId
    before_validation :normalize_manual_slug
    validate :slug_available
  end

  class_methods do
    def friendly_slug(source)
      friendly_id source, use: %i[sequentially_slugged history finders]
      define_method(:slug_source_attribute) { source }
      # Se definen en la clase para tener prioridad sobre los de friendly_id
      define_method(:should_generate_new_friendly_id?) do
        slug.blank? || (will_save_change_to_attribute?(source) && !will_save_change_to_slug?)
      end
      define_method(:normalize_friendly_id) do |value|
        value.to_s.parameterize.first(80).delete_suffix("-").presence || "item"
      end
    end
  end

  private

  def normalize_manual_slug
    return unless slug.present? && will_save_change_to_slug?
    self.slug = normalize_friendly_id(slug)
  end

  # Un slug escrito a mano no puede repetirse (ni con uno viejo de otro registro).
  def slug_available
    return unless slug.present? && will_save_change_to_slug? && persisted?
    taken = self.class.unscoped.where(slug: slug).where.not(id: id).exists? ||
            FriendlyId::Slug.where(slug: slug, sluggable_type: self.class.base_class.name).where.not(sluggable_id: id).exists?
    errors.add(:slug, "ya está en uso") if taken
  end
end
