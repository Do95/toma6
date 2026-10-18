# Migración de datos para instalaciones que ya estaban corriendo:
# - Crea las secciones del inicio copiando los textos que ya tenías en
#   "Contenido del sitio" (portada, nosotros, títulos de secciones, contacto).
# - Crea las secciones por defecto (historia + galería) de cada proyecto.
# - Crea las plantillas de correo con sus textos iniciales.
# Es segura de correr más de una vez: no duplica nada que ya exista.
class SeedSectionsAndEmailTemplates < ActiveRecord::Migration[8.0]
  def up
    Section.reset_column_information
    EmailTemplate.reset_column_information
    EmailLog.reset_column_information

    settings = SiteSetting.first || SiteSetting.create!(site_name: "toma6")
    Section.ensure_home_defaults!(settings)
    Project.kept.find_each { |project| Section.ensure_project_defaults!(project) }
    EmailTemplate.ensure_defaults!

    say "Secciones del inicio: #{Section.home.count} · secciones de proyectos: #{Section.where(page: 'project').count} · plantillas de correo: #{EmailTemplate.count}"
  end

  def down
    # Las tablas se eliminan al revertir las migraciones anteriores.
  end
end
