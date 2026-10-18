class BaseUploader < CarrierWave::Uploader::Base
  # El almacenamiento (disco o S3) se configura en config/initializers/carrierwave.rb

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id || 'tmp'}"
  end

  # Nombre de archivo único para evitar cachés viejas al reemplazar una imagen.
  def filename
    return unless original_filename
    base = File.basename(original_filename, ".*").parameterize.presence || "archivo"
    "#{secure_token}-#{base.first(60)}.#{file.extension.to_s.downcase}"
  end

  private

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.hex(4))
  end
end
