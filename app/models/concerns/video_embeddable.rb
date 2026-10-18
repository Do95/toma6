# Convierte enlaces de YouTube o Vimeo (campo video_link) en URL para insertar.
module VideoEmbeddable
  extend ActiveSupport::Concern

  def embed_url
    return if video_link.blank?
    if (m = video_link.match(%r{(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/shorts/|youtube\.com/embed/)([\w-]{6,})}))
      "https://www.youtube-nocookie.com/embed/#{m[1]}?rel=0"
    elsif (m = video_link.match(%r{vimeo\.com/(?:video/)?(\d+)}))
      "https://player.vimeo.com/video/#{m[1]}"
    end
  end
end
