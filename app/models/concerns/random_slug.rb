# Identificador al azar para la URL de registros que no tienen un texto propio
# (historial de correos y de actividad, publicaciones, ubicaciones de fotos).
module RandomSlug
  extend ActiveSupport::Concern

  included do
    extend FriendlyId
    friendly_id :slug, use: :finders
    before_validation(on: :create) { self.slug ||= SecureRandom.alphanumeric(12).downcase }
  end
end
