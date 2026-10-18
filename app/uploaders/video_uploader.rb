class VideoUploader < BaseUploader
  def extension_allowlist = %w[mp4 webm mov m4v]
  def content_type_allowlist = [%r{video/}]
  def size_range = (1.byte)..(400.megabytes)
end
