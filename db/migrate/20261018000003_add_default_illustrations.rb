# Datos: ilustraciones por defecto en las secciones existentes y una sección
# personalizada de ejemplo en el inicio (oculta en instalaciones que ya
# estaban corriendo, para no cambiar el sitio publicado sin que lo decidas).
class AddDefaultIllustrations < ActiveRecord::Migration[8.0]
  def up
    Section.reset_column_information
    SectionBlock.reset_column_information

    Section::KINDS.each do |kind, config|
      next unless config[:illustration]
      Section.unscoped.where(kind: kind, illustration: nil).update_all(illustration: config[:illustration])
    end

    unless Section.home.where(kind: "custom").exists?
      Section.create_home_example!(published: false)
      say "Se creó la sección de ejemplo «Todo lo que necesitás» (oculta). Activala en Secciones del inicio."
    end
  end

  def down
    Section.unscoped.update_all(illustration: nil)
  end
end
