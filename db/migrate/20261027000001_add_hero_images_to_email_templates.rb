# Foto de portada administrable en cada plantilla de correo: se sube, se elige de
# la galería o queda la predeterminada. Sin ninguna, el correo va sin portada.
class AddHeroImagesToEmailTemplates < ActiveRecord::Migration[8.0]
  DEFAULT_HEROES = {
    "quote_request_client" => "mail/hero-solicitud.jpg",
    "quote_sent_client" => "mail/hero-propuesta.jpg",
    "quote_accepted_client" => "mail/hero-confirmada.jpg",
    "user_invitation" => "mail/hero-bienvenida.jpg"
  }.freeze

  def up
    add_column :email_templates, :hero_image, :string
    add_column :email_templates, :hero_asset, :string
    add_reference :email_templates, :hero_image_media_item, foreign_key: { to_table: :media_items, on_delete: :nullify }
    DEFAULT_HEROES.each { |key, asset| execute("UPDATE email_templates SET hero_asset = #{quote(asset)} WHERE key = #{quote(key)}") }
  end

  def down
    remove_reference :email_templates, :hero_image_media_item, foreign_key: true
    remove_column :email_templates, :hero_asset
    remove_column :email_templates, :hero_image
  end
end
