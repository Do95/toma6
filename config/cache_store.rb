# Dónde se guarda el caché, según lo que esté configurado:
#   - CACHE_STORE=none           → sin caché
#   - CACHE_REDIS_URL o REDIS_URL → Redis (compartido entre servidores, sobrevive a los deploys)
#   - nada                       → memoria del servidor (se vacía en cada deploy)
# La invalidación no depende del proveedor: la versión del contenido vive en la base (SiteCache).
module CacheStoreConfig
  def self.store
    return :null_store if ENV["CACHE_STORE"] == "none"

    url = ENV["CACHE_REDIS_URL"].presence || ENV["REDIS_URL"].presence || ENV['REDISCLOUD_URL'].presence
    return [:memory_store, { size: 64 * 1024 * 1024 }] unless url

    [:redis_cache_store, {
      url: url,
      namespace: "toma6-cache",
      expires_in: 7 * 24 * 3600, # 7 días
      # Heroku Redis usa TLS con certificado propio
      ssl_params: ({ verify_mode: OpenSSL::SSL::VERIFY_NONE } if url.start_with?("rediss://")),
      # Si Redis no responde, la página se arma sin caché en vez de fallar
      error_handler: ->(method:, returning:, exception:) { Rails.logger.warn("[Cache] #{method}: #{exception.class} #{exception.message}") }
    }.compact]
  end

  def self.label
    case Array(store).first
    when :redis_cache_store then "Redis"
    when :memory_store then "Memoria del servidor"
    else "Desactivado"
    end
  end
end
