require "tempfile"

# Abre un archivo subido como archivo local, esté guardado en disco o en S3.
# (En Heroku las fotos viven en S3, así que no siempre hay una ruta local.)
module UploadFile
  module_function

  # Ruta local legible (descarga a un archivo temporal si hace falta)
  def local_path(uploader)
    return if uploader.blank?
    path = uploader.path
    return path if path && File.exist?(path)
    ext = uploader.file.respond_to?(:filename) ? File.extname(uploader.file.filename.to_s) : ""
    tmp = Tempfile.new(["upload", ext], binmode: true)
    tmp.write(uploader.read)
    tmp.flush
    (@tempfiles ||= []) << tmp # que no se borre mientras se usa
    tmp.path
  rescue StandardError => e
    Rails.logger.warn("[UploadFile] #{e.message}")
    nil
  end

  # Archivo para asignar a otro registro (por ejemplo, al duplicar)
  def open(uploader)
    path = local_path(uploader) or return
    file = File.open(path, "rb")
    f = uploader.file
    name = (f.respond_to?(:original_filename) && f.original_filename.presence) ||
           (f.respond_to?(:filename) && f.filename.presence) || File.basename(path)
    name = File.basename(name.to_s)
    file.define_singleton_method(:original_filename) { name }
    file
  end
end
