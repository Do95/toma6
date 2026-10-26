# Versión del contenido público: sube con cada cambio en el panel y es parte de la
# clave del caché de las páginas. Vive en la base para que todos los servidores la vean.
class AddContentVersionToSiteSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :site_settings, :content_version, :integer, null: false, default: 0
  end
end
