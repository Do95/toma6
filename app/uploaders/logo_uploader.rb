class LogoUploader < BaseUploader
  include CarrierWave::MiniMagick

  version :small do
    process resize_to_limit: [400, 200]
  end

  def extension_allowlist = %w[png jpg jpeg]
  def size_range = (1.byte)..(10.megabytes)
end
