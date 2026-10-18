class ImageUploader < BaseUploader
  include CarrierWave::MiniMagick

  # Huella del archivo original para detectar fotos repetidas. Va primero en la
  # cola para leer el archivo antes de que se procese (rotar, limpiar, achicar).
  self._before_callbacks = _before_callbacks.merge(cache: [:capture_checksum] + _before_callbacks[:cache])

  process :auto_orient_and_strip
  process resize_to_limit: [2800, 2800]
  process :store_dimensions

  version :thumb do
    process resize_to_fill: [480, 480]
  end

  version :medium do
    process resize_to_limit: [1100, 1100]
  end

  version :large do
    process resize_to_limit: [2000, 2000]
  end

  # JPEG cuadrado-compatible para Instagram/Facebook (máx. 1440 px).
  version :social do
    process resize_to_limit: [1440, 1440]
    process convert: "jpg"
    force_extension ".jpg"
  end

  def extension_allowlist = %w[jpg jpeg png webp]
  def content_type_allowlist = [%r{image/}]
  def size_range = (1.byte)..(25.megabytes)

  private

  def capture_checksum(new_file)
    return if version_name.present? # las versiones (miniaturas) no cuentan
    return unless mounted_as == :image && model.respond_to?(:checksum=) && new_file&.path
    model.checksum = Digest::MD5.file(new_file.path).hexdigest
  rescue StandardError
    nil
  end

  def auto_orient_and_strip
    manipulate! do |img|
      img.auto_orient
      img.strip
      img
    end
  end

  def store_dimensions
    return unless file && model.respond_to?(:width=) && mounted_as == :image
    w, h = ::MiniMagick::Image.open(file.path).dimensions
    model.width = w
    model.height = h
  rescue StandardError => e
    Rails.logger.warn("[ImageUploader] No se pudieron leer las dimensiones: #{e.message}")
  end
end
