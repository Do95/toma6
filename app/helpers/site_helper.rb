module SiteHelper
  def nav_link(label, path)
    link_to label, path, class: (current_page?(path) ? "is-current" : nil)
  end

  def social_links
    [
      [settings.instagram_url, :instagram, "Instagram"],
      [settings.facebook_url, :facebook, "Facebook"],
      [settings.tiktok_url, nil, "TikTok"],
      [settings.youtube_url, :play, "YouTube"]
    ].select { |url, _, _| url.present? }
  end

  def handle_from(url)
    url.to_s.sub(%r{\Ahttps?://(www\.)?[^/]+/}, "").delete_suffix("/").then { |h| h.start_with?("@") ? h : "@#{h}" }
  end

  # Atributos data del mosaico que lee el visor (lightbox) y los filtros.
  # Una foto puede estar en varias galerías: album/project son listas.
  def tile_data(item, albums: nil)
    album_slugs = albums || item.placements.filter_map { |p| p.album&.slug }
    project_slugs = item.placements.filter_map { |p| (p.album ? p.album.project : p.project)&.slug }.uniq
    {
      action: "lightbox#open",
      lightbox_target: "item",
      filter_target: "item",
      kind: item.kind,
      category: item.category&.slug.to_s,
      project: project_slugs.join(" "),
      album: album_slugs.join(" "),
      lb: item.lightbox_data.merge(also: gallery_links(item)).to_json
    }
  end

  # Galerías visibles donde aparece la foto (para "Aparece en" del visor)
  def gallery_links(item)
    item.placements.filter_map do |p|
      if p.album
        album = p.album
        next unless album.visible? && (album.project.nil? || album.project.visible?)
        { label: album.project ? "#{album.project.title} › #{album.title}" : album.title, url: album_path(album.slug) }
      elsif p.project&.visible?
        { label: p.project.title, url: project_path(p.project.slug) }
      end
    end.uniq
  end

  def media_tile(item, version: :medium, extra_class: nil, albums: nil)
    data = tile_data(item, albums: albums)
    data[:preview] = item.video.url if item.video?
    shared = data[:album].split.size + (albums ? 0 : item.placements.count { |p| p.album_id.nil? })
    content_tag(:button, type: "button", id: "foto-#{item.id}", class: ["ph-tile", ("is-video" if item.video?), extra_class].compact.join(" "),
                         style: "aspect-ratio:#{item.ratio}", data: data,
                         aria: { label: "#{item.video? ? 'Reproducir video' : 'Ver foto'}: #{item.title}" }) do
      safe_join([
        image_tag(item.image_url(version) || "", alt: [item.title, item.description].compact_blank.join(": "),
                                                 loading: "lazy", decoding: "async", width: item.width, height: item.height),
        (content_tag(:span, safe_join([play_svg, item.duration.presence || "Video"]), class: "vid-badge") if item.video?),
        (content_tag(:span, "En #{shared} galerías", class: "shared-chip") if shared > 1 && !albums)
      ].compact)
    end
  end

  def play_svg
    '<svg viewBox="0 0 12 12" aria-hidden="true"><path d="M3 1.5v9l7.5-4.5z" fill="currentColor"/></svg>'.html_safe
  end

  def service_image(service, attr, fallback)
    uploader = service.public_send(attr)
    uploader.present? ? uploader.url(:medium) : image_path("site/#{fallback}")
  end

  def gallery_count_text(counts)
    photos = counts["photo"].to_i
    videos = counts["video"].to_i
    parts = []
    parts << "#{photos} #{photos == 1 ? 'foto' : 'fotos'}" if photos.positive?
    parts << "#{videos} #{videos == 1 ? 'video' : 'videos'}" if videos.positive?
    parts.join(" y ")
  end
end

module SiteHelper
  # A dónde lleva cada sección desde el menú
  def section_href(section)
    case section.kind
    when "services" then services_path
    when "work" then projects_path
    when "gallery_teaser" then gallery_path
    else "#{root_path}##{section.anchor}"
    end
  end

  def section_button(label, url, klass: "btn primary")
    return if label.blank? || url.blank?
    link_to label, url, class: klass
  end

  def section_classes(section, *extra)
    # sx--tipo: modificador de la sección (no choca con las clases de sus elementos internos)
    ["sx", "sx--#{section.kind.dasherize}", "theme-#{section.theme}", *extra].join(" ")
  end
end

module SiteHelper
  # Datos estructurados (schema.org) para Google. Se arma en Ruby y se escapa
  # para que sea seguro dentro de <script>.
  def organization_json_ld
    data = {
      "@context" => "https://schema.org",
      "@type" => "ProfessionalService",
      "name" => settings.site_name,
      "url" => settings.public_base_url,
      "description" => settings.seo_description,
      "email" => settings.contact_email,
      "telephone" => settings.phone.presence || settings.whatsapp_number,
      "image" => absolute_url(image_path("site/og-toma6.jpg")),
      "address" => { "@type" => "PostalAddress", "addressLocality" => settings.city, "addressCountry" => settings.country }.compact_blank,
      "sameAs" => social_links.map(&:first)
    }
    data.delete("address") if data["address"].keys == ["@type"]
    tag.script(ERB::Util.json_escape(data.compact_blank.to_json).html_safe, type: "application/ld+json")
  end
end
