# Subida directa del navegador a S3, sin pasar por el servidor (en Heroku cada request
# tiene 30 s y 512 MB: un video de cientos de MB no entra).
#
# 1. El panel pide una URL firmada (presign) para un archivo de un tipo y tamaño válidos.
# 2. El navegador sube el archivo con PUT a uploads/direct/<uuid>/<nombre>.
# 3. Al guardar el registro, attach! lo copia dentro de S3 a su carpeta definitiva
#    (la misma que usaría CarrierWave), borra el temporal y guarda el nombre en la columna.
#
# Sin S3 (desarrollo con public/uploads) no está activo y los formularios suben como siempre.
module DirectUpload
  PREFIX = "uploads/direct".freeze
  KEY_FORMAT = %r{\A#{PREFIX}/\h{8}-\h{4}-\h{4}-\h{4}-\h{12}/[a-z0-9][a-z0-9._-]{0,80}\z}
  EXPIRES = 15.minutes

  KINDS = {
    "video" => { exts: VideoUploader.new.extension_allowlist, type: %r{\Avideo/}, max: 400.megabytes }
  }.freeze

  class Invalid < StandardError; end

  module_function

  def enabled? = UploadsStorage.s3?

  def rules(kind) = KINDS.fetch(kind.to_s) { raise Invalid, "Tipo de archivo no permitido." }

  # Valida antes de subir (así nadie espera un minuto para enterarse de que el archivo no sirve)
  def presign(filename:, content_type:, size:, kind:)
    raise Invalid, "La subida directa a S3 no está configurada." unless enabled?
    r = rules(kind)
    ext = File.extname(filename.to_s).delete(".").downcase
    raise Invalid, "Formato no permitido: subí #{r[:exts].join(', ')}." unless r[:exts].include?(ext)
    raise Invalid, "Ese archivo no parece un video." unless content_type.to_s.match?(r[:type])
    size = size.to_i
    raise Invalid, "El archivo está vacío." unless size.positive?
    raise Invalid, "Pesa #{(size / 1.megabyte.to_f).round} MB: el máximo es #{r[:max] / 1.megabyte} MB." if size > r[:max]

    key = "#{PREFIX}/#{SecureRandom.uuid}/#{safe_name(filename)}"
    headers = { "Content-Type" => content_type }
    headers["x-amz-acl"] = ENV["S3_OBJECT_ACL"] if ENV["S3_OBJECT_ACL"].present?
    url = storage.put_object_url(bucket, key, EXPIRES.from_now.to_i, headers)
    { url: url, key: key, headers: headers }
  end

  # Comprueba que la subida terminó y que es lo que se firmó. Devuelve un mensaje de error o nil.
  def problem_with(key, kind)
    return "La subida no es válida." unless key.to_s.match?(KEY_FORMAT)
    r = rules(kind)
    head = storage.head_object(bucket, key).headers
    size = head["Content-Length"].to_i
    return "El archivo no terminó de subirse. Probá de nuevo." unless size.positive?
    return "El archivo supera los #{r[:max] / 1.megabyte} MB." if size > r[:max]
    return "Ese archivo no es un video." unless head["Content-Type"].to_s.match?(r[:type])
    nil
  rescue Excon::Error::NotFound
    "El archivo no terminó de subirse. Probá de nuevo."
  end

  # Mueve el archivo subido a la carpeta del registro y lo deja asignado a la columna.
  def attach!(record, column, key)
    uploader = record.public_send(column)
    old = uploader.present? ? uploader : nil
    base = File.basename(key, ".*").parameterize.presence || "archivo"
    name = "#{SecureRandom.hex(4)}-#{base.first(60)}#{File.extname(key).downcase}"
    dest = "#{uploader.store_dir}/#{name}"
    head = storage.head_object(bucket, key).headers
    options = { "x-amz-metadata-directive" => "REPLACE", "Content-Type" => head["Content-Type"],
                "Cache-Control" => "public, max-age=31536000, immutable" }
    options["x-amz-acl"] = ENV["S3_OBJECT_ACL"] if ENV["S3_OBJECT_ACL"].present?
    storage.copy_object(bucket, key, bucket, dest, options)
    storage.delete_object(bucket, key)
    record.update_column(column, name)
    old&.remove! # el video anterior, si se reemplazó
  end

  def safe_name(filename)
    ext = File.extname(filename.to_s).downcase
    base = File.basename(filename.to_s, ".*").parameterize.presence || "archivo"
    "#{base.first(60)}#{ext}"
  end

  def storage = @storage ||= Fog::Storage.new(CarrierWave::Uploader::Base.fog_credentials)
  def bucket = CarrierWave::Uploader::Base.fog_directory
end
