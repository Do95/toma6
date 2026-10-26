# Contenido que se ve en el sitio público: al guardarlo (o borrarlo) se renueva el caché.
module BustsSiteCache
  extend ActiveSupport::Concern

  included do
    after_commit { SiteCache.bump! }
  end
end
