# Ayudas para los correos. Los programas de correo (Gmail, Outlook) ignoran gran
# parte del CSS, así que los estilos van en línea, en cada etiqueta.
module MailerHelper
  INK = "#171717"
  INK_2 = "#55524e"
  INK_3 = "#8a8784"
  RED = "#b63830"
  LINE = "#ebe9e5"
  FONT = "Helvetica,Arial,sans-serif"

  # Texto de la plantilla (párrafos, **negrita**, ==resaltado==) con estilos en línea
  def mail_rich(html)
    html.to_s
        .gsub("<p>", %(<p style="margin:0 0 16px;font-family:#{FONT};font-size:16px;line-height:1.6;color:#{INK_2}">))
        .gsub("<strong>", %(<strong style="color:#{INK};font-weight:bold">))
        .gsub('<span class="mark mark-inline">', %(<span style="background:#f8e5e3;color:#{RED};font-weight:bold;padding:1px 5px;border-radius:3px">))
        .html_safe
  end

  # Versión en texto plano (la parte de texto mejora la entrega y se lee en cualquier lado)
  def mail_text(html)
    text = html.to_s.gsub(%r{</p>\s*}, "\n\n").gsub(/<br\s*\/?>/, "\n")
    CGI.unescapeHTML(strip_tags(text)).gsub(/[ \t]+/, " ").gsub(/\n{3,}/, "\n\n").strip
  end

  # Botón que se ve bien también en Outlook (tabla con fondo, no solo CSS)
  def mail_button(label, url)
    <<~HTML.html_safe
      <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:8px 0 4px">
        <tr><td align="center" bgcolor="#{RED}" style="border-radius:6px;background:#{RED}">
          <a href="#{ERB::Util.h(url)}" target="_blank" style="display:inline-block;padding:15px 28px;font-family:#{FONT};font-size:15px;font-weight:bold;color:#ffffff;text-decoration:none;border-radius:6px;letter-spacing:.02em">#{ERB::Util.h(label)} &rarr;</a>
        </td></tr>
      </table>
    HTML
  end

  def mail_image_url(path) = absolute_url(image_path(path))

  def mail_social_links
    [["Instagram", settings.instagram_url], ["Facebook", settings.facebook_url],
     ["TikTok", settings.tiktok_url], ["YouTube", settings.youtube_url]].select { |_, url| url.present? }
  end
end
