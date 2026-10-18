require "net/http"
require "json"

module Meta
  class Error < StandardError; end

  # Cliente mínimo de la Graph API de Meta (Facebook e Instagram).
  class Client
    GRAPH = "https://graph.facebook.com".freeze
    DIALOG = "https://www.facebook.com".freeze
    SCOPES = %w[pages_show_list pages_read_engagement pages_manage_posts business_management
                instagram_basic instagram_content_publish].freeze

    def initialize(integration)
      @integration = integration
    end

    # ---------- OAuth ----------
    def authorize_url(redirect_uri:, state:)
      query = URI.encode_www_form(client_id: @integration.app_id, redirect_uri: redirect_uri, state: state,
                                  scope: SCOPES.join(","), response_type: "code")
      "#{DIALOG}/#{version}/dialog/oauth?#{query}"
    end

    def exchange_code(code, redirect_uri:)
      short = get("oauth/access_token", client_id: @integration.app_id, client_secret: @integration.app_secret,
                                        redirect_uri: redirect_uri, code: code)
      long = get("oauth/access_token", grant_type: "fb_exchange_token", client_id: @integration.app_id,
                                       client_secret: @integration.app_secret, fb_exchange_token: short["access_token"])
      { token: long["access_token"], expires_at: long["expires_in"] ? Time.current + long["expires_in"].to_i.seconds : nil }
    end

    def pages(user_token = @integration.user_access_token)
      data = get("me/accounts", access_token: user_token, limit: 100,
                                fields: "id,name,access_token,instagram_business_account{id,username}")
      Array(data["data"]).map do |p|
        ig = p["instagram_business_account"] || {}
        { id: p["id"], name: p["name"], token: p["access_token"], ig_id: ig["id"], ig_username: ig["username"] }
      end
    end

    # ---------- Facebook ----------
    def publish_to_page(message:, link: nil, image_url: nil)
      token = @integration.page_access_token
      page = @integration.page_id
      if image_url
        caption = [message, link].compact_blank.join("\n\n")
        res = post("#{page}/photos", access_token: token, url: image_url, caption: caption)
        id = res["post_id"] || res["id"]
      else
        res = post("#{page}/feed", access_token: token, message: message, link: link.presence)
        id = res["id"]
      end
      permalink = get(id, access_token: token, fields: "permalink_url")["permalink_url"] rescue nil
      { id: id, permalink: permalink }
    end

    # ---------- Instagram ----------
    def publish_to_instagram(caption:, image_url:)
      token = @integration.page_access_token
      ig = @integration.instagram_account_id
      container = post("#{ig}/media", access_token: token, image_url: image_url, caption: caption)["id"]
      wait_for_container(container, token)
      media_id = post("#{ig}/media_publish", access_token: token, creation_id: container)["id"]
      permalink = get(media_id, access_token: token, fields: "permalink")["permalink"] rescue nil
      { id: media_id, permalink: permalink }
    end

    private

    def version = @integration.graph_version.presence || "v23.0"

    def wait_for_container(id, token, attempts: 10)
      attempts.times do
        status = get(id, access_token: token, fields: "status_code")["status_code"]
        return if status == "FINISHED"
        raise Error, "Instagram rechazó la imagen (estado #{status})." if %w[ERROR EXPIRED].include?(status)
        sleep 3
      end
      raise Error, "Instagram tardó demasiado en procesar la imagen. Probá de nuevo en unos minutos."
    end

    def get(path, params = {})
      uri = URI("#{GRAPH}/#{version}/#{path}")
      uri.query = URI.encode_www_form(params.compact)
      handle Net::HTTP.get_response(uri)
    end

    def post(path, params = {})
      uri = URI("#{GRAPH}/#{version}/#{path}")
      handle Net::HTTP.post_form(uri, params.compact.transform_values(&:to_s))
    end

    def handle(response)
      body = JSON.parse(response.body.presence || "{}")
      if body["error"]
        message = body["error"]["error_user_msg"].presence || body["error"]["message"]
        raise Error, "Meta: #{message}"
      end
      raise Error, "Meta respondió #{response.code}." unless response.is_a?(Net::HTTPSuccess)
      body
    rescue JSON::ParserError
      raise Error, "Respuesta inesperada de Meta (#{response.code})."
    end
  end
end
