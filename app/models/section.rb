# Bloques que arman el inicio y la página de cada proyecto. Se ordenan, se
# ocultan, se duplican y se agregan nuevos desde el panel.
class Section < ApplicationRecord
  include Auditable
  include SoftDeletable
  include Positionable
  include Publishable
  include VideoEmbeddable

  F = {
    eyebrow: "Antetítulo", title: "Título", lead: "Bajada", body: "Texto", note: "Nota", items: "Elementos",
    image: "Imagen", image_side: "Lado de la imagen", video: "Video", button: "Botón principal",
    secondary: "Botón secundario", theme: "Fondo", album: "Álbum", illustration: "Ilustración",
    columns: "Columnas", embed: "Código"
  }.freeze

  # fields: campos que se editan. labels: textos de ayuda propios del tipo.
  KINDS = {
    # ---- Fijas del inicio (usan contenido de otras secciones del panel) ----
    "hero" => { label: "Portada", icon: :film, builtin: true, pages: %w[home], fields: %i[title lead button secondary image],
                labels: { title: "Frase destacada", lead: "Texto debajo del logo", image: "Logo grande (opcional, reemplaza al de la marca)" },
                description: "Logo grande, diafragma animado, frase y botones." },
    "ticker" => { label: "Cinta de palabras", icon: :sliders, builtin: true, pages: %w[home], fields: %i[body theme],
                  labels: { body: "Palabras separadas por coma" }, description: "Cinta animada que cruza la pantalla." },
    "manifesto" => { label: "Manifiesto", icon: :megaphone, builtin: true, pages: %w[home], fields: %i[body],
                     labels: { body: "Frase (se revela palabra por palabra)" }, description: "Frase grande sobre rojo que se revela al bajar." },
    "about" => { label: "Quiénes somos", icon: :users, builtin: true, pages: %w[home], fields: %i[title lead body note],
                 labels: { lead: "Frase de entrada", note: "Cierre" }, description: "Texto del equipo y los valores (se editan en Valores)." },
    "services" => { label: "Servicios", icon: :briefcase, builtin: true, pages: %w[home], fields: %i[title lead button],
                    description: "Tarjetas animadas de cada servicio. También titula la página /servicios." },
    "work" => { label: "Trabajos recientes", icon: :film, builtin: true, pages: %w[home], fields: %i[title lead],
                description: "Proyectos destacados con scroll horizontal. También titula /proyectos." },
    "gallery_teaser" => { label: "Adelanto de galería", icon: :image, builtin: true, pages: %w[home], fields: %i[title lead button],
                          description: "Fotos destacadas con parallax. También titula /galeria." },
    "process" => { label: "Cómo trabajamos", icon: :steps, builtin: true, pages: %w[home], fields: %i[title lead],
                   description: "Pasos del proceso (se editan en Proceso)." },
    "faq" => { label: "Preguntas frecuentes", icon: :help, builtin: true, pages: %w[home], fields: %i[title lead],
               description: "Preguntas desplegables (se editan en Preguntas frecuentes)." },
    "contact" => { label: "Contacto", icon: :send, builtin: true, pages: %w[home], fields: %i[title lead button],
                   description: "Cierre con botones, correo y redes." },
    # ---- Fijas del proyecto ----
    "project_story" => { label: "Historia del proyecto", icon: :file, builtin: true, pages: %w[project], fields: %i[title],
                         labels: { title: "Título (opcional)" }, description: "Datos (cliente, fecha, lugar, servicios) y la historia del proyecto." },
    "project_gallery" => { label: "Galería del proyecto", icon: :image, builtin: true, pages: %w[project], fields: %i[title lead],
                           description: "Todas las fotos con pestañas por álbum." },
    # ---- Bloques que se pueden agregar ----
    "custom" => { label: "Sección personalizada", icon: :sliders, pages: %w[home project], fields: %i[eyebrow title lead columns theme],
                  description: "Armala vos: de 1 a 4 columnas, cada una con ilustración o foto, título, texto y botón." },
    "text" => { label: "Texto", icon: :file, pages: %w[home project], fields: %i[eyebrow title body button illustration theme],
                labels: { illustration: "Ilustración (opcional, arriba del título)" },
                description: "Título y párrafos. Ideal para contar algo." },
    "text_image" => { label: "Texto con imagen", icon: :layout, pages: %w[home project], illustration: "camara",
                      fields: %i[eyebrow title body image illustration image_side button theme],
                      labels: { image: "Foto (si no subís una, se usa la ilustración)" },
                      description: "Texto a un lado, foto o ilustración al otro." },
    "image" => { label: "Imagen grande", icon: :image, pages: %w[home project], fields: %i[image note theme],
                 labels: { note: "Pie de foto (opcional)" }, description: "Una foto a todo el ancho." },
    "video" => { label: "Video", icon: :play, pages: %w[home project], fields: %i[eyebrow title video note theme],
                 labels: { note: "Texto debajo (opcional)" }, description: "YouTube, Vimeo o un archivo propio." },
    "cta" => { label: "Llamado a la acción", icon: :megaphone, pages: %w[home project], illustration: "claqueta",
               fields: %i[title lead button secondary illustration theme],
               description: "Banda llamativa con botones (por ejemplo, Cotizar)." },
    "quote" => { label: "Testimonio", icon: :star, pages: %w[home project], illustration: "mensaje",
                 fields: %i[body note image illustration theme],
                 labels: { body: "Cita", note: "Quién lo dice (nombre, empresa)", image: "Foto (opcional; si no hay, se usa la ilustración)" },
                 description: "Una frase de un cliente, grande y destacada." },
    "stats" => { label: "Cifras", icon: :activity, pages: %w[home project], fields: %i[eyebrow title items theme],
                 labels: { items: "Una cifra por línea:  valor | descripción" }, description: "Números que impactan: 150+ eventos, 5 años…" },
    "features" => { label: "Puntos destacados", icon: :check, pages: %w[home project], illustration: "auto",
                    fields: %i[eyebrow title lead items theme],
                    labels: { items: "Uno por línea:  título | texto | ilustración (opcional: camara, dron, luces…)" },
                    description: "Lista de beneficios en tarjetas, cada una con su ilustración." },
    "gallery" => { label: "Galería de un álbum", icon: :folder, pages: %w[home project], fields: %i[eyebrow title lead album button theme],
                   description: "Las fotos de un álbum, con visor." },
    "embed" => { label: "Código embebido", icon: :globe, pages: %w[home project], admin_only: true, fields: %i[eyebrow title lead embed theme],
                 description: "Mapa de Google, Calendly, un formulario o un video de otra plataforma. Solo administradores." }
  }.freeze

  THEMES = { "dark" => "Carbón", "charcoal" => "Gris oscuro", "red" => "Rojo toma6", "light" => "Blanco" }.freeze
  LAYOUTS = { "1" => "1 columna", "2" => "2 columnas", "3" => "3 columnas", "4" => "4 columnas",
              "2-1" => "Ancha + angosta", "1-2" => "Angosta + ancha" }.freeze
  BLOCK_STYLES = { "card" => "Tarjetas con borde", "plain" => "Sin borde" }.freeze
  PAGES = %w[home project].freeze

  mount_uploader :image, ImageUploader
  mount_uploader :video, VideoUploader

  belongs_to :project, optional: true, inverse_of: :sections
  belongs_to :album, optional: true
  has_many :blocks, -> { kept.ordered }, class_name: "SectionBlock", inverse_of: :section
  has_many :all_blocks, class_name: "SectionBlock", dependent: :destroy

  soft_delete_cascade :all_blocks
  accepts_nested_attributes_for :blocks, reject_if: ->(a) { a[:id].blank? && a.slice(:title, :body, :eyebrow, :image).values.all?(&:blank?) }

  validates :kind, inclusion: { in: KINDS.keys }
  validates :page, inclusion: { in: PAGES }
  validates :theme, inclusion: { in: THEMES.keys }
  validates :image_side, inclusion: { in: %w[left right] }
  validates :project, presence: true, if: -> { page == "project" }
  validates :video_link, format: { with: %r{\Ahttps?://}i }, allow_blank: true
  validates :button_url, :secondary_url, format: { with: %r{\A(https?://|/|#|mailto:|tel:)}i, message: "debe empezar con https://, / o #" }, allow_blank: true
  # (condicionadas para que las migraciones anteriores a estas columnas sigan corriendo)
  with_options if: -> { has_attribute?(:layout) } do
    validates :layout, inclusion: { in: LAYOUTS.keys }
    validates :align, inclusion: { in: %w[left center] }
    validates :block_style, inclusion: { in: BLOCK_STYLES.keys }
    validates :illustration, inclusion: { in: ->(_) { Illustrations.keys + ["none"] } }, allow_blank: true
    validates :embed_height, numericality: { only_integer: true, in: 100..2000 }
  end
  validate :kind_allowed_on_page

  after_initialize :apply_default_illustration, if: :new_record?

  before_validation :set_anchor

  scope :home, -> { where(page: "home", project_id: nil) }
  scope :for_project, ->(project) { where(page: "project", project_id: project.id) }
  scope :in_nav, -> { where(show_in_nav: true) }

  def self.permission_resource = :content
  def self.addable_kinds(page) = KINDS.reject { |_, c| c[:builtin] }.select { |_, c| c[:pages].include?(page) }

  def config = KINDS.fetch(kind, {})
  def kind_label = config[:label] || kind.humanize
  def builtin? = config[:builtin].present?
  def field?(name) = config.fetch(:fields, []).include?(name)
  def field_label(name) = config.dig(:labels, name) || F[name]
  def display_name = title.presence || kind_label
  def nav_text = nav_label.presence || title.to_s.delete_suffix(".").presence || kind_label

  # "150+ | Eventos" → [["150+", "Eventos"], …]
  def item_rows
    items.to_s.lines.map(&:strip).reject(&:blank?).map { |l| l.split("|", 3).map(&:strip) }
  end

  def admin_only? = config[:admin_only].present?

  # Ilustración a mostrar (nil si no lleva o si eligieron "Ninguna")
  def illustration_key
    key = illustration.presence
    key && key != "none" && Illustrations.exists?(key) ? key : nil
  end

  # Para "Puntos destacados": la que eligieron por línea o una rotativa
  def item_illustration(row, index)
    key = row[2].to_s.parameterize
    Illustrations.exists?(key) ? key : Illustrations.cycle(index)
  end

  def words = body.to_s.split(",").map(&:strip).reject(&:blank?)

  def duplicate!
    copy = dup
    copy.assign_attributes(title: [title.presence, "(copia)"].compact.join(" "), anchor: nil, show_in_nav: false,
                           position: position + 1, created_by_id: nil, updated_by_id: nil)
    copy.image = UploadFile.open(image) if image.present?
    copy.save!
    blocks.each do |b|
      nb = copy.all_blocks.build(b.attributes.slice("illustration", "eyebrow", "title", "body", "button_label", "button_url", "position"))
      nb.image = UploadFile.open(b.image) if b.image.present?
      nb.save!
    end
    copy
  end

  # ---------- Valores iniciales ----------
  def self.ensure_home_defaults!(settings = SiteSetting.current)
    return if unscoped.where(page: "home").exists?
    default_home_rows(settings).each_with_index { |attrs, i| create!(attrs.merge(page: "home", position: i + 1)) }
  end

  # Vuelve a crear las secciones fijas del inicio que falten (por ejemplo, si se eliminaron)
  def self.restore_home_defaults!(settings = SiteSetting.current)
    present = home.kept.pluck(:kind)
    created = []
    default_home_rows(settings).each_with_index do |attrs, i|
      next if present.include?(attrs[:kind])
      present << attrs[:kind]
      # Si está en la papelera, se recupera con sus textos; si no, se crea de nuevo
      trashed = home.trashed.where(kind: attrs[:kind]).order(deleted_at: :desc).first
      if trashed
        trashed.restore!
        created << trashed
      else
        created << create!(attrs.merge(page: "home", position: i + 1))
      end
    end
    created
  end

  def self.missing_home_builtins
    KINDS.select { |_, c| c[:builtin] && c[:pages].include?("home") }.keys - home.kept.pluck(:kind)
  end

  def self.default_home_rows(settings = SiteSetting.current)
    s = settings
    rows = [
      { kind: "hero", title: s.hero_claim.presence || "Cada toma cuenta", lead: s.hero_subtitle,
        button_label: s.hero_primary_cta.presence || "Cotizar proyecto", button_url: "/servicios#cotizador",
        secondary_label: s.hero_secondary_cta.presence || "Ver trabajos", secondary_url: "/proyectos" },
      { kind: "ticker", body: s.ticker_primary.presence || "Fotografía, Reels, Video, Edición", theme: "red" },
      { kind: "manifesto", body: s.manifesto },
      { kind: "about", title: s.about_title, lead: s.about_lead, body: s.about_body, note: s.about_closing,
        show_in_nav: true, nav_label: "Nosotros", anchor: "nosotros" },
      { kind: "services", title: s.services_title, lead: s.services_intro, button_label: "Armá tu cotización ›",
        button_url: "/servicios#cotizador", show_in_nav: true, nav_label: "Servicios", anchor: "servicios" },
      { kind: "work", title: s.work_title, lead: s.work_intro, show_in_nav: true, nav_label: "Trabajos", anchor: "trabajos" },
      { kind: "gallery_teaser", title: s.gallery_title, lead: s.gallery_intro, button_label: "Ver fotos y videos",
        show_in_nav: true, nav_label: "Galería", anchor: "fotos" },
      { kind: "process", title: s.process_title, lead: s.process_intro, show_in_nav: true, nav_label: "Proceso", anchor: "proceso" },
      { kind: "faq", title: s.faq_title, lead: s.faq_intro, anchor: "preguntas" },
      { kind: "ticker", body: s.ticker_secondary.presence || "Cada toma cuenta, Capturamos historias", theme: "light" },
      { kind: "contact", title: s.contact_title, lead: s.contact_intro, button_label: "Cotizar proyecto",
        button_url: "/servicios#cotizador", show_in_nav: true, nav_label: "Contacto", anchor: "contacto" }
    ]
  end

  def self.ensure_project_defaults!(project)
    return if unscoped.where(page: "project", project_id: project.id).exists?
    restore_project_defaults!(project)
  end

  def self.restore_project_defaults!(project)
    present = for_project(project).kept.pluck(:kind)
    created = []
    created << create!(page: "project", project: project, kind: "project_story", position: 1) unless present.include?("project_story")
    created << create!(page: "project", project: project, kind: "project_gallery", title: "Galería", position: 2) unless present.include?("project_gallery")
    created
  end

  # Sección personalizada de ejemplo con ilustraciones
  def self.create_home_example!(published: true)
    after = home.kept.find_by(kind: "services")
    section = create!(page: "home", kind: "custom", eyebrow: "Todo en un solo equipo", title: "Todo lo que necesitás.",
                      lead: "Del guion a la entrega, con equipo propio y un mismo equipo de principio a fin.",
                      layout: "4", align: "center", block_style: "card", theme: "charcoal", published: published,
                      position: after ? after.position : 0)
    [["camara", "Video 4K", "Varias cámaras, estabilizadores y sonido profesional."],
     ["dron", "Tomas aéreas", "Dron para planos que cuentan el lugar desde arriba."],
     ["luces", "Luz de estudio", "Iluminación propia para que cada toma se vea como tiene que verse."],
     ["calendario", "Entregas a tiempo", "Fechas claras desde la propuesta. Sin sorpresas."]].each_with_index do |(ill, t, b), i|
      section.all_blocks.create!(illustration: ill, title: t, body: b, position: i + 1)
    end
    section
  end

  # Sección del inicio de un tipo (para titular las páginas internas).
  def self.home_kind(kind) = home.kept.ordered.find_by(kind: kind)

  private

  def apply_default_illustration
    self.illustration ||= config[:illustration] if has_attribute?(:illustration) && config[:illustration] && config[:illustration] != "auto"
  end

  def kind_allowed_on_page
    errors.add(:kind, "no se puede usar en esta página") unless config.fetch(:pages, []).include?(page)
  end

  def set_anchor
    base = (anchor.presence || title.presence || kind).to_s.parameterize.first(40).presence || kind
    candidate = base
    n = 2
    scope = self.class.unscoped.where(page: page, project_id: project_id).where.not(id: id)
    while scope.where(anchor: candidate).exists?
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.anchor = candidate
  end
end
