# Todas las fotos, videos y logos que se suben desde el panel van a un bucket de S3
# (o compatible: Cloudflare R2, DigitalOcean Spaces, Backblaze B2).
#
# Variables:
#   S3_BUCKET, S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY, S3_REGION   (obligatorias)
#   S3_ENDPOINT, S3_PATH_STYLE   solo para R2 / Spaces / B2
#   S3_PUBLIC_URL                dominio o CDN público del bucket (opcional)
#   S3_OBJECT_ACL=public-read    solo si tu bucket usa ACL (buckets viejos). Por
#                                defecto no se manda ACL y la lectura pública la da
#                                la política del bucket (lo que AWS recomienda hoy).
#
# En producción S3 es obligatorio. En desarrollo, si no hay S3_BUCKET, se guarda en
# el disco (public/uploads). Para un VPS sin S3: UPLOADS_STORAGE=local.
module UploadsStorage
  REQUIRED = %w[S3_BUCKET S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY].freeze

  def self.s3? = ENV["UPLOADS_STORAGE"] != "local" && ENV["S3_BUCKET"].present?

  def self.check!
    return if s3? || ENV["UPLOADS_STORAGE"] == "local"
    return unless Rails.env.production?
    return if ENV["SECRET_KEY_BASE_DUMMY"].present? # compilando assets: no hace falta S3
    missing = REQUIRED.reject { |k| ENV[k].present? }
    raise <<~MSG
      Faltan las variables de S3 para guardar las fotos: #{missing.join(', ')}.
      Configuralas (ver README → «Fotos en S3»). Si este servidor guarda las fotos
      en su propio disco (un VPS, no Heroku), definí UPLOADS_STORAGE=local.
    MSG
  end

  def self.public_host
    return ENV["S3_PUBLIC_URL"].chomp("/") if ENV["S3_PUBLIC_URL"].present?
    nil # CarrierWave arma la URL pública estándar del bucket
  end

  # URL pública de un archivo del bucket (igual a la que usan las fotos del sitio)
  def self.public_url_for(key)
    return "#{public_host}/#{key}" if public_host
    bucket = ENV.fetch("S3_BUCKET")
    if ENV["S3_ENDPOINT"].present?
      endpoint = ENV["S3_ENDPOINT"].chomp("/")
      ENV["S3_PATH_STYLE"] == "true" ? "#{endpoint}/#{bucket}/#{key}" : endpoint.sub("://", "://#{bucket}.") + "/#{key}"
    else
      region = ENV.fetch("S3_REGION", "us-east-1")
      "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"
    end
  end
end

# Subir sin ACL: los buckets nuevos de AWS tienen las ACL desactivadas y rechazan
# "public-read". Las URLs siguen siendo públicas y permanentes (no firmadas).
module CarrierWaveWithoutAcl
  def store(new_file)
    return super if new_file.is_a?(self.class)
    fog_file = new_file.to_file
    @content_type ||= new_file.content_type
    @file = directory.files.create({
      body: fog_file || new_file.read,
      content_type: @content_type,
      key: path
    }.merge(@uploader.fog_attributes))
    fog_file.close if fog_file && !fog_file.closed?
    true
  end

  def acl_header = {}

  def directory
    @directory ||= connection.directories.new(key: @uploader.fog_directory)
  end
end

UploadsStorage.check!

# ImageMagick (miniaturas) usa disco en lugar de RAM cuando una foto es enorme: en un dyno de
# 512 MB, una foto de dron procesándose junto a otras subidas provocaba R14/R15.
# Los procesos de ImageMagick heredan estas variables; se pueden ajustar desde el entorno.
ENV["MAGICK_MEMORY_LIMIT"] ||= "256MiB"
ENV["MAGICK_MAP_LIMIT"] ||= "512MiB"

CarrierWave.configure do |config|
  config.cache_dir = Rails.root.join("tmp/uploads").to_s
  config.cache_storage = :file # el procesamiento (miniaturas) se hace en el servidor

  if UploadsStorage.s3?
    require "fog/aws"
    config.storage = :fog
    config.fog_provider = "fog/aws"
    config.fog_credentials = {
      provider: "AWS",
      aws_access_key_id: ENV.fetch("S3_ACCESS_KEY_ID"),
      aws_secret_access_key: ENV.fetch("S3_SECRET_ACCESS_KEY"),
      region: ENV.fetch("S3_REGION", "us-east-1"),
      endpoint: ENV["S3_ENDPOINT"].presence,
      path_style: ENV["S3_PATH_STYLE"] == "true"
    }.compact
    config.fog_directory = ENV.fetch("S3_BUCKET")
    config.fog_public = true # URLs públicas y permanentes
    config.fog_attributes = { "Cache-Control" => "public, max-age=31536000, immutable" }
    config.asset_host = UploadsStorage.public_host if UploadsStorage.public_host
    CarrierWave::Storage::Fog::File.prepend(CarrierWaveWithoutAcl) unless ENV["S3_OBJECT_ACL"] == "public-read"
  else
    config.storage = :file
    config.root = Rails.root.join("public").to_s
    config.permissions = 0o644
    config.directory_permissions = 0o755
  end
end
