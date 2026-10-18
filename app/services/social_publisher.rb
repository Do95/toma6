# Publica una SocialPost en las redes elegidas y deja registro del resultado.
class SocialPublisher
  def self.call(post) = new(post).call

  def initialize(post)
    @post = post
    @integration = Integration.meta
  end

  def call
    raise Meta::Error, "No hay una página de Facebook conectada." unless @integration&.page_connected?

    @post.update_columns(status: "publishing", error_message: nil)
    client = Meta::Client.new(@integration)
    errors = []
    done = []
    image_url = @post.public_image_url

    if @post.to_facebook? && @post.facebook_post_id.blank?
      begin
        res = client.publish_to_page(message: @post.body, link: @post.link, image_url: image_url)
        @post.update_columns(facebook_post_id: res[:id], facebook_permalink: res[:permalink])
        done << "Facebook"
      rescue Meta::Error, SocketError, Timeout::Error => e
        errors << "Facebook: #{e.message}"
      end
    end

    if @post.to_instagram? && @post.instagram_media_id.blank?
      begin
        res = client.publish_to_instagram(caption: [@post.body, @post.link].compact_blank.join("\n\n"), image_url: image_url)
        @post.update_columns(instagram_media_id: res[:id], instagram_permalink: res[:permalink])
        done << "Instagram"
      rescue Meta::Error, SocketError, Timeout::Error => e
        errors << "Instagram: #{e.message}"
      end
    end

    status = if errors.empty? then "published"
             elsif done.any? then "partial"
             else "failed"
             end
    @post.update_columns(status: status, error_message: errors.join("\n").presence,
                         published_at: (done.any? ? Time.current : @post.published_at), updated_at: Time.current)
    ActivityLog.record!(@post, "publish", { "redes" => [nil, done.join(", ").presence || "ninguna"],
                                            "errores" => [nil, errors.join(" | ").presence] }.compact_blank)
    @integration.update_columns(last_error: errors.last) if errors.any?
    @post
  rescue Meta::Error => e
    @post.update_columns(status: "failed", error_message: e.message)
    @post
  end
end
