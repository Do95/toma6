# Caché de las páginas públicas. Se arman una vez y se reutilizan hasta que algo
# cambia. La clave lleva dos versiones:
#   - la del contenido (en la base, para que la vean todos los servidores): sube
#     con cada cambio en el panel o con «Vaciar caché»;
#   - la del código: cambia en cada deploy, así un cambio de diseño nunca muestra
#     páginas viejas aunque el caché (Redis) sobreviva al deploy.
module SiteCache
  REVISION = (ENV["HEROKU_SLUG_COMMIT"].presence || ENV["SOURCE_VERSION"].presence || Time.now.to_i.to_s).first(12)

  def self.key(*parts) = ["site", REVISION, "v#{SiteSetting.current.content_version}", *parts]

  def self.version = SiteSetting.current.content_version

  def self.bump!
    SiteSetting.update_all("content_version = content_version + 1")
    Current.site_setting = nil # dentro de este mismo pedido, que se lea la versión nueva
  end
end
