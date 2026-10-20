module AdminHelper
  def nav_item(label, path, icon_name, active: nil, badge: nil, locked: false)
    active = active.nil? ? current_page?(path) || request.path.start_with?(path.split("?").first + "/") : active
    content_tag(:a, href: path, class: ["side-link", ("is-active" if active), ("is-locked" if locked)].compact.join(" "),
                    aria: { current: (active ? "page" : nil) }) do
      safe_join([
        icon(icon_name),
        content_tag(:span, label, class: "side-label"),
        (content_tag(:span, badge, class: "side-badge") if badge.to_i.positive?),
        (icon(:lock, size: 14, klass: "side-lock") if locked)
      ].compact)
    end
  end

  def status_badge(status, label)
    tone = {
      "published" => "ok", "accepted" => "ok", "converted" => "ok",
      "sent" => "info", "scheduled" => "info", "contacted" => "info", "publishing" => "info",
      "draft" => "muted", "discarded" => "muted",
      "new" => "red", "failed" => "red", "rejected" => "red", "partial" => "warn", "expired" => "warn"
    }.fetch(status.to_s, "muted")
    content_tag(:span, label, class: "badge badge-#{tone}")
  end

  def published_badge(record)
    record.published? ? content_tag(:span, "Publicado", class: "badge badge-ok") : content_tag(:span, "Oculto", class: "badge badge-muted")
  end

  def avatar_for(user, size: 28)
    return content_tag(:span, "S", class: "avatar", style: "--s:#{size}px", title: "Sistema") unless user
    if user.avatar.present?
      image_tag(user.avatar.url, class: "avatar", style: "--s:#{size}px", alt: user.name, title: user.name)
    else
      hue = (user.id.to_i * 47) % 360
      content_tag(:span, user.initials, class: "avatar", style: "--s:#{size}px;--h:#{hue}", title: user.name)
    end
  end

  # "Editado por Ana · hace 2 horas"
  def audit_line(record)
    return unless record.respond_to?(:updated_at)
    who = record.try(:updater) || record.try(:creator)
    verb = record.try(:updated_by_id) && record.updated_at > record.created_at + 2.seconds ? "Editado" : "Creado"
    content_tag(:span, class: "audit-line") do
      safe_join([avatar_for(who, size: 18), " #{verb} por #{who&.name || 'Sistema'} · ",
                 content_tag(:time, "hace #{time_ago_in_words(record.updated_at)}", datetime: record.updated_at.iso8601,
                                                                                    title: l(record.updated_at, format: :long))])
    end
  end

  # Botones para eliminar: a la papelera (recuperable) y, si tenés permiso,
  # eliminar definitivamente. Ambos con modal de confirmación.
  def trash_button(record, label: "Eliminar", path: nil, return_to: nil)
    resource = record.class.permission_resource
    name = record.display_name.truncate(40)
    soft = if can?(resource, :delete)
             button_to path || polymorphic_path([:admin, record]), method: :delete, class: "btn btn-ghost btn-danger",
                       form: { data: { turbo_confirm: "«#{name}» va a la papelera. Podés restaurarlo durante #{settings.trash_retention_days} días.",
                                       confirm_title: "¿Enviar a la papelera?", confirm_button: "Enviar a la papelera", confirm_variant: "danger" } } do
               safe_join([icon(:trash, size: 16), label])
             end
           end
    hard = if can?(resource, :purge) && can?(:trash, :purge)
             button_to admin_hard_delete_path(type: record.class.base_class.name, id: record.id, return_to: return_to || hard_delete_return(record)),
                       method: :delete, class: "btn btn-sm btn-purge",
                       form: { data: { turbo_confirm: "Se borra «#{name}» para siempre, con sus archivos. No va a la papelera y no se puede deshacer.",
                                       confirm_title: "¿Eliminar definitivamente?", confirm_button: "Eliminar para siempre", confirm_variant: "danger" } } do
               safe_join([icon(:x, size: 14), "Eliminar definitivamente"])
             end
           end
    return if soft.nil? && hard.nil?
    content_tag(:div, safe_join([soft, hard].compact), class: "delete-actions")
  end

  def hard_delete_return(record)
    case record
    when Section then record.project ? edit_admin_project_path(record.project, tab: "secciones") : admin_sections_path
    when SectionBlock then admin_sections_path
    else polymorphic_path([:admin, record.class])
    end
  rescue StandardError
    admin_root_path
  end

  def field_hint(text) = content_tag(:p, text, class: "hint")

  def form_errors(record)
    return if record.errors.empty?
    content_tag(:div, class: "form-errors", role: "alert") do
      safe_join([
        content_tag(:strong, record.errors.count == 1 ? "Revisá este dato:" : "Revisá estos #{record.errors.count} datos:"),
        content_tag(:ul, safe_join(record.errors.full_messages.map { |m| content_tag(:li, m) }))
      ])
    end
  end

  # logo: true muestra la vista previa entera (sin recortar) sobre fondo oscuro.
  def image_field(form, attribute, label:, hint: nil, version: :thumb, logo: false)
    uploader = form.object.public_send(attribute)
    # Algunos uploaders (el avatar) no tienen miniaturas: se usa el archivo tal cual
    src = (uploader.versions.key?(version) ? uploader.url(version) : uploader.url) if uploader.present?
    content_tag(:div, class: "field image-field", data: { controller: "image-preview" }) do
      safe_join([
        form.label(attribute, label),
        content_tag(:label, class: "dropzone-mini") do
          safe_join([
            tag.img(src: src, class: ["preview", ("is-logo" if logo), ("is-empty" if uploader.blank?)].compact.join(" "),
                    alt: "", data: { image_preview_target: "preview" }),
            content_tag(:span, safe_join([icon(:upload, size: 16), uploader.present? ? "Reemplazar" : "Elegir imagen"]), class: "dz-cta"),
            form.file_field(attribute, accept: "image/*", class: "sr-only", data: { action: "image-preview#show" })
          ])
        end,
        (content_tag(:label, safe_join([form.check_box(:"remove_#{attribute}"), " Quitar imagen"]), class: "check-inline") if uploader.present?),
        (field_hint(hint) if hint)
      ].compact)
    end
  end

  def pagination_nav
    p = pagination
    return unless p && p.total_pages > 1
    content_tag(:nav, class: "pager", aria: { label: "Paginación" }) do
      safe_join([
        (p.prev_page ? link_to("‹ Anterior", url_with(page: p.prev_page), class: "btn btn-ghost") : content_tag(:span, "")),
        content_tag(:span, p.range_label, class: "pager-info"),
        (p.next_page ? link_to("Siguiente ›", url_with(page: p.next_page), class: "btn btn-ghost") : content_tag(:span, ""))
      ])
    end
  end

  def filter_chip(label, params_hash, active)
    link_to label, url_with(params_hash.merge("page" => nil)), class: ["chip-f", ("is-on" if active)].compact.join(" ")
  end

  # URL actual cambiando algunos parámetros (nil los quita).
  def url_with(changes)
    changes = changes.transform_keys(&:to_s)
    query = request.query_parameters.except(*changes.keys).merge(changes).compact_blank
    query.empty? ? request.path : "#{request.path}?#{query.to_query}"
  end

  def changeset_value(value)
    case value
    when nil, "" then content_tag(:em, "vacío", class: "muted")
    when true then "Sí"
    when false then "No"
    when Array then value.join(", ")
    else value.to_s.truncate(240)
    end
  end

  def humanize_attribute(type, attr)
    klass = type&.safe_constantize
    klass.respond_to?(:human_attribute_name) ? klass.human_attribute_name(attr) : attr.to_s.humanize
  end

  def subject_link(log)
    return log.subject_label if log.action == "purge" || log.subject_type.blank?
    record = log.subject_type.safe_constantize&.find_by(id: log.subject_id)
    return content_tag(:span, log.subject_label, class: "muted") unless record
    path = admin_path_for(record)
    path ? link_to(log.subject_label, path) : log.subject_label
  end

  def admin_path_for(record)
    case record
    when SiteSetting then edit_admin_site_content_path
    when ServiceOption then edit_admin_service_path(record.service)
    when Integration then admin_integration_path
    when QuoteRequest, Quote then polymorphic_path([:admin, record])
    else
      record.respond_to?(:trashed?) && record.trashed? ? admin_trash_path : edit_polymorphic_path([:admin, record])
    end
  rescue NoMethodError, ActionController::UrlGenerationError
    nil
  end
end

module AdminHelper
  NEW_LABELS = {
    "Faq" => "Nueva pregunta", "ProcessStep" => "Nuevo paso", "AboutValue" => "Nuevo valor",
    "Category" => "Nueva categoría", "Service" => "Nuevo servicio", "Plan" => "Nuevo plan", "Project" => "Nuevo proyecto",
    "Album" => "Nuevo álbum", "MediaItem" => "Nuevo medio", "User" => "Nuevo usuario",
    "Quote" => "Nueva cotización", "SocialPost" => "Nueva publicación"
  }.freeze

  def new_label(klass) = NEW_LABELS.fetch(klass.name, "Nuevo")

  def switch_field(form, attribute, title, description = nil)
    content_tag(:label, class: "switch") do
      safe_join([
        form.check_box(attribute),
        content_tag(:span, "", class: "track"),
        content_tag(:span, class: "switch-text") do
          safe_join([content_tag(:strong, title), (content_tag(:small, description) if description)].compact)
        end
      ])
    end
  end
end
