class AvatarUploader < BaseUploader
  include CarrierWave::MiniMagick

  process :auto_orient
  process resize_to_fill: [256, 256]

  def extension_allowlist = %w[jpg jpeg png webp]
  def size_range = (1.byte)..(8.megabytes)

  private

  def auto_orient
    manipulate! { |img| img.auto_orient; img.strip; img }
  end
end
