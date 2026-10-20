# Contenido inicial: replica el sitio actual de toma6 para que el panel arranque
# con todo cargado. Es seguro correrlo más de una vez (no duplica contenido).
#
#   bin/rails db:seed
#
MEDIA = Rails.root.join("db/seeds/media")
def media_file(name) = File.open(MEDIA.join(name))

puts "→ Usuario administrador"
admin = User.find_or_initialize_by(email: ENV.fetch("ADMIN_EMAIL", "admin@toma6.com"))
if admin.new_record?
  admin.assign_attributes(name: "Administrador", role: "admin",
                          password: ENV.fetch("ADMIN_PASSWORD", "cambiame-ya-123"))
  admin.save!
  puts "  Creado #{admin.email} (cambiá la contraseña al entrar)"
end
Current.user = admin

puts "→ Contenido del sitio"
s = SiteSetting.current
if s.hero_subtitle.blank?
  s.update!(
    site_name: "toma6",
    legal_name: "toma6",
    hero_claim: "Cada toma cuenta",
    hero_subtitle: "Fotografía y video para eventos sociales y proyectos multimedia. Momentos reales, convertidos en historias.",
    hero_primary_cta: "Cotizar proyecto",
    hero_secondary_cta: "Ver trabajos",
    ticker_primary: "Fotografía, Reels, Video, Edición",
    ticker_secondary: "Cada toma cuenta, Capturamos historias",
    manifesto: "Cada evento, cada mirada y cada emoción merece convertirse en un recuerdo que perdure en el tiempo.",
    about_title: "Quiénes somos.",
    about_lead: "toma6 nace con el objetivo de capturar **momentos reales** y transformarlos en historias que perduren en el tiempo.",
    about_body: "Somos un equipo audiovisual especializado en ==fotografía y video== para eventos sociales y proyectos multimedia.\n\nNuestro propósito es simple: que cada evento, cada mirada y cada emoción se conviertan en un recuerdo visual inolvidable.",
    about_closing: "En **toma6** no solo grabamos eventos, ==capturamos historias==.",
    services_title: "Tu historia, bien contada.",
    services_intro: "Nos contás lo que querés mostrar y nosotros nos ocupamos del resto. Elegí un servicio o combiná varios, a la medida de tu proyecto.",
    work_title: "Trabajos recientes.",
    work_intro: "Algunos proyectos que nos encantó hacer.",
    gallery_title: "Galería.",
    gallery_intro: "Un poco de todo lo que hacemos: producto, retratos, eventos y detrás de escena.",
    process_title: "Cómo trabajamos.",
    process_intro: "Simple y sin vueltas. Siempre sabés en qué punto está tu proyecto.",
    faq_title: "Preguntas frecuentes.",
    faq_intro: "Lo que más nos consultan antes de arrancar un proyecto.",
    quote_title: "Armá tu cotización.",
    quote_intro: "Elegí los servicios, sumá extras y mirá el precio al instante. Te respondemos con una propuesta cerrada.",
    contact_title: "Tu próxima toma empieza acá",
    contact_intro: "==Escribinos== y contanos qué tenés en mente. Te respondemos rápido con una propuesta.",
    contact_email: "hola@toma6.com",
    whatsapp_number: "",
    city: "San Salvador",
    country: "El Salvador",
    instagram_url: "https://www.instagram.com/toma6sv/",
    facebook_url: "https://www.facebook.com/toma6sv",
    site_url: ENV["APP_HOST"].present? ? "#{ENV.fetch('APP_PROTOCOL', 'https')}://#{ENV['APP_HOST']}" : nil,
    seo_title: "toma6 | Fotografía y video para eventos, reels y podcast",
    seo_description: "Equipo audiovisual especializado en fotografía y video para eventos sociales y proyectos multimedia: reels, edición y podcast. Capturamos historias.",
    footer_text: "Fotografía y video para eventos y proyectos multimedia",
    estimator_disclaimer: "Es un precio estimado, sin IVA. Después de una primera charla te enviamos una propuesta con precio cerrado, sin sorpresas.",
    bundle_discount_percent: 10,
    bundle_min_services: 2,
    quote_default_notes: "Incluye traslado dentro del área metropolitana de San Salvador. Entrega del material editado en un plazo de 10 a 15 días hábiles.",
    quote_default_terms: "Para reservar la fecha se requiere un anticipo del 50%. El saldo se cancela el día del evento o a la entrega.\nIncluye dos rondas de ajustes en la edición.\nLa cotización no incluye viáticos fuera del área metropolitana salvo que se indique.",
    quote_payment_info: "Transferencia bancaria o depósito. Te enviamos los datos de la cuenta al confirmar."
  )
  s.og_image = media_file("og-toma6.jpg")
  s.save!
end

puts "→ Secciones del inicio"
Section.ensure_home_defaults!(s)
unless Section.home.where(kind: "stats").exists?
  stats = Section.create!(page: "home", kind: "stats", eyebrow: "toma6 en números", title: "Cada toma cuenta.",
                          items: "150+ | Eventos cubiertos\n40+ | Marcas que confían\n24 h | Para tu propuesta\n4K | En cada rodaje",
                          theme: "charcoal", published: false, position: Section.home.find_by(kind: "process")&.position.to_i)
  puts "  Ejemplo «Cifras» creado oculto: activalo desde Secciones del inicio"
end

unless Section.home.where(kind: "custom").exists?
  Section.create_home_example!(published: true)
  puts "  Sección personalizada con ilustraciones «Todo lo que necesitás»"
end

puts "→ Plantillas de correo"
EmailTemplate.ensure_defaults!

puts "→ Valores, proceso y preguntas"
if AboutValue.none?
  [["Creatividad", "Ideas y encuadres pensados para cada historia."],
   ["Compromiso", "Cumplimos lo que acordamos, en tiempo y forma."],
   ["Calidad profesional", "Equipo, luz y edición a la altura de cada momento."]].each_with_index do |(t, d), i|
    AboutValue.create!(title: t, description: d, position: i + 1)
  end
end

if ProcessStep.none?
  [["Charlamos", "Nos contás tu idea, tu objetivo y tu presupuesto."],
   ["Proponemos", "Te enviamos una propuesta con idea, fechas y precio cerrado."],
   ["Grabamos", "Vamos con todo el equipo, en estudio o donde haga falta."],
   ["Editamos", "Edición, color y sonido, con rondas de ajustes incluidas."],
   ["Entregamos", "Archivos listos para cada red, pantalla o impresión."]].each_with_index do |(t, d), i|
    ProcessStep.create!(title: t, description: d, position: i + 1)
  end
end

if Faq.none?
  [["¿Cubren eventos sociales?", "Sí, es nuestra especialidad. Hacemos fotografía y video de bodas, cumpleaños, quinceaños, egresos y eventos corporativos, desde los preparativos hasta el final de la fiesta."],
   ["¿Qué servicios ofrece toma6?", "Producción audiovisual, fotografía, edición y postproducción, contenido para redes sociales y grabación de podcast. Podés contratar un servicio o combinar varios en un mismo proyecto."],
   ["¿Cuánto cuesta un proyecto?", "Depende de la duración, el equipo y lo que necesites entregar. Usá el cotizador para ver un estimado al instante; después de una primera charla te enviamos una propuesta con precio cerrado, sin sorpresas."],
   ["¿Cuánto tardan en entregar?", "Cada propuesta incluye una fecha de entrega. Los proyectos cortos, como una sesión de fotos o un pack de reels, suelen estar listos en pocos días."],
   ["¿Graban en estudio o en locación?", "En los dos. Vamos con todo el equipo a tu local, oficina, evento o al lugar que haga falta."],
   ["¿Qué necesito para grabar un podcast con ustedes?", "Solo tu idea y tus invitados. Nosotros ponemos las cámaras, los micrófonos, la luz y la edición, y te entregamos el episodio listo para YouTube, Spotify y clips para redes."],
   ["¿En qué formatos entregan el material?", "En los formatos que necesites: vertical para reels y TikTok, horizontal para YouTube y web, y fotos en alta resolución para imprimir."]].each_with_index do |(q, a), i|
    Faq.create!(question: q, answer: a, position: i + 1)
  end
end

puts "→ Categorías"
cats = %w[Producto Retrato Eventos Paisaje Backstage].each_with_index.to_h do |name, i|
  [name, Category.find_or_create_by!(name: name) { |c| c.position = i + 1 }]
end

puts "→ Servicios y opciones del cotizador (precios de ejemplo: ajustalos en el panel)"
if Service.none?
  services = [
    { title: "Producción audiovisual", visual_style: "video", tags: "Eventos, Institucionales, Spots",
      summary: "Videos de eventos, institucionales y spots. Nos encargamos de todo: idea, guion, rodaje y entrega final.",
      base_price: 450, price_unit: "por proyecto", images: ["imagen-04.jpg"],
      options: [
        { name: "4 horas de cobertura", kind: "choice", group_name: "Duración", price: 0, default_selected: true },
        { name: "8 horas de cobertura", kind: "choice", group_name: "Duración", price: 250 },
        { name: "Jornada completa (12 h)", kind: "choice", group_name: "Duración", price: 450 },
        { name: "Cámara adicional", kind: "quantity", price: 120, unit_label: "por cámara", max_quantity: 3 },
        { name: "Tomas con dron", kind: "addon", price: 150, description: "Sujeto a clima y permisos del lugar." },
        { name: "Guion y storyboard", kind: "addon", price: 90 }
      ] },
    { title: "Fotografía", visual_style: "photo", tags: "Eventos, Retrato, Producto",
      summary: "Eventos sociales, retratos y producto. Fotos con buena luz y edición cuidada, listas para compartir, imprimir o usar en redes.",
      base_price: 180, price_unit: "por sesión", images: %w[imagen-05.jpg imagen-06.jpg imagen-07.jpg],
      options: [
        { name: "Sesión de 2 horas", kind: "choice", group_name: "Duración", price: 0, default_selected: true },
        { name: "Media jornada (4 h)", kind: "choice", group_name: "Duración", price: 120 },
        { name: "Jornada completa (8 h)", kind: "choice", group_name: "Duración", price: 300 },
        { name: "Fotos editadas extra", kind: "quantity", price: 25, unit_label: "por paquete de 10", max_quantity: 20 },
        { name: "Segundo fotógrafo", kind: "addon", price: 140 },
        { name: "Álbum impreso", kind: "addon", price: 95, description: "30 × 30 cm, 20 páginas." }
      ] },
    { title: "Edición y postproducción", visual_style: "edit", tags: "Montaje, Color, Sonido",
      summary: "¿Ya tenés material? Lo editamos por vos: montaje, color, sonido, subtítulos y gráficos.",
      base_price: 120, price_unit: "por video", images: ["imagen-08.jpg"],
      options: [
        { name: "Hasta 1 minuto", kind: "choice", group_name: "Duración final", price: 0, default_selected: true },
        { name: "Hasta 5 minutos", kind: "choice", group_name: "Duración final", price: 80 },
        { name: "Hasta 15 minutos", kind: "choice", group_name: "Duración final", price: 200 },
        { name: "Subtítulos", kind: "addon", price: 30 },
        { name: "Corrección de color avanzada", kind: "addon", price: 60 },
        { name: "Versiones para redes", kind: "quantity", price: 20, unit_label: "por formato", max_quantity: 5 }
      ] },
    { title: "Contenido para redes", visual_style: "social", tags: "Reels, TikTok, Stories",
      summary: "Reels, TikToks y stories pensados para cada plataforma. Grabamos en una jornada contenido para todo el mes.",
      base_price: 250, price_unit: "por pack mensual", images: %w[imagen-09.jpg imagen-10.jpg imagen-11.jpg],
      options: [
        { name: "Pack 4 reels", kind: "choice", group_name: "Cantidad de reels", price: 0, default_selected: true },
        { name: "Pack 8 reels", kind: "choice", group_name: "Cantidad de reels", price: 180 },
        { name: "Pack 12 reels", kind: "choice", group_name: "Cantidad de reels", price: 330 },
        { name: "Stories diseñadas", kind: "quantity", price: 10, unit_label: "c/u", max_quantity: 30 },
        { name: "Guiones y copys", kind: "addon", price: 60 }
      ] },
    { title: "Grabación de podcast", visual_style: "podcast", tags: "Video podcast, Audio, Clips para redes",
      summary: "Grabamos tu podcast en video y audio, con varias cámaras, buen sonido y edición lista para YouTube y Spotify.",
      base_price: 150, price_unit: "por episodio", images: [],
      options: [
        { name: "Episodios adicionales", kind: "quantity", price: 120, unit_label: "por episodio", max_quantity: 12 },
        { name: "Tercera cámara", kind: "addon", price: 50 },
        { name: "Clips verticales para redes", kind: "quantity", price: 15, unit_label: "por clip", max_quantity: 10 }
      ] }
  ]
  services.each_with_index do |data, i|
    opts = data.delete(:options)
    images = data.delete(:images)
    service = Service.new(data.merge(position: i + 1, price_prefix: "Desde"))
    service.image = media_file("img/#{images[0]}") if images[0]
    service.image_secondary = media_file("img/#{images[1]}") if images[1]
    service.image_tertiary = media_file("img/#{images[2]}") if images[2]
    service.save!
    opts.each_with_index { |o, j| service.options.create!(o.merge(position: j + 1)) }
  end
end

puts "→ Planes con precio cerrado (ejemplo: ajustalos en Panel → Planes)"
if Plan.none?
  svc = Service.all.index_by(&:title)
  [
    { title: "Sesión esencial", price: 220, price_unit: "por sesión", summary: "Fotos profesionales para tu marca, perfil o evento chico.",
      features: "2 horas de sesión\n40 fotos editadas\nEntrega en 5 días hábiles", services: ["Fotografía"] },
    { title: "Evento completo", price: 990, price_unit: "por evento", badge: "Más elegido", highlighted: true,
      summary: "Foto y video para bodas, quinceaños y eventos corporativos.",
      features: "8 horas de cobertura\nFotógrafo y camarógrafo\n300 fotos editadas\nVideo resumen de 3 minutos",
      services: ["Fotografía", "Producción audiovisual", "Edición y postproducción"] },
    { title: "Redes del mes", price: 390, price_unit: "por mes", summary: "Una jornada de grabación y contenido listo para todo el mes.",
      features: "8 reels editados\nGuiones y copys\nVersiones para Instagram y TikTok", services: ["Contenido para redes"] }
  ].each_with_index do |data, i|
    names = data.delete(:services)
    Plan.create!(data.merge(position: i + 1, services: names.filter_map { |n| svc[n] }))
  end
end

puts "→ Proyectos, álbumes y galería"
if Project.none?
  svc = Service.all.index_by(&:title)
  # Crea la foto en la biblioteca y la ubica en su galería (álbum o general del proyecto)
  def add_media(attrs)
    file = attrs.delete(:file)
    video = attrs.delete(:video)
    album = attrs.delete(:album)
    project = attrs.delete(:project)
    item = MediaItem.new(attrs)
    item.image = media_file("img/#{file}")
    item.video = media_file("videos/#{video}") if video
    item.kind = video ? "video" : "photo"
    item.duration ||= "0:07" if video
    item.save!
    MediaPlacement.attach!(item, album) if album
    MediaPlacement.attach!(item, project) if project && !album
    item
  end

  p1 = Project.create!(title: "Lanzamiento de producto", category_label: "Spot publicitario", featured: true, position: 1,
                       summary: "Spot corto para presentar un producto nuevo en redes y web.",
                       body: "Una marca local necesitaba presentar su producto estrella con una pieza corta, pensada para **redes y web**.\n\nTrabajamos la idea, el guion y el rodaje en estudio, con luz de producto y tomas de detalle.",
                       cover: media_file("img/imagen-12.jpg"), video: media_file("videos/spot-producto.mp4"),
                       services: [svc["Producción audiovisual"], svc["Edición y postproducción"]].compact)
  add_media(project: p1, file: "imagen-12.jpg", video: "spot-producto.mp4", title: "Spot de producto", description: "Pieza corta para presentar un producto en redes y web.", category: cats["Producto"], featured: true)
  a1 = Album.create!(project: p1, title: "Fotos de producto", description: "Fotos fijas que acompañaron la campaña.")
  add_media(album: a1, file: "imagen-24.jpg", title: "Café de especialidad", description: "Fotos de producto para tienda online y catálogo.", category: cats["Producto"], featured: true)
  add_media(album: a1, file: "imagen-29.jpg", title: "Jugos naturales", description: "Producto en acción, pensado para publicidad en redes.", category: cats["Producto"])

  p2 = Project.create!(title: "Oficios de la ciudad", category_label: "Documental", featured: true, position: 2,
                       summary: "Serie documental sobre personas y las historias detrás de su trabajo.",
                       body: "Una serie de retratos y entrevistas a artesanos y trabajadores de la ciudad.\n\nCada capítulo cuenta ==una historia real==, con luz natural y el ritmo de cada taller.",
                       cover: media_file("img/imagen-13.jpg"), services: [svc["Fotografía"], svc["Producción audiovisual"]].compact)
  add_media(project: p2, file: "imagen-30.jpg", title: "Oficios", description: "Retrato documental para una serie sobre historias reales.", category: cats["Retrato"], featured: true)
  a2 = Album.create!(project: p2, title: "Retratos", description: "Las personas detrás de cada oficio.")
  add_media(album: a2, file: "imagen-20.jpg", title: "Retrato en estudio", description: "Sesión de retrato profesional para perfiles, prensa o web.", category: cats["Retrato"])
  add_media(album: a2, file: "imagen-26.jpg", title: "Sesión en exteriores", description: "Retrato con luz natural para marca personal o book.", category: cats["Retrato"], featured: true)

  p3 = Project.create!(title: "Colección verano", category_label: "Fotografía de producto", featured: true, position: 3,
                       summary: "Sesión de producto con fondos de color para tienda online.",
                       body: "Fondos de color, luz dura y composición limpia para una tienda online que lanzaba su colección de temporada.",
                       cover: media_file("img/imagen-14.jpg"), services: [svc["Fotografía"]].compact)
  a3 = Album.create!(project: p3, title: "Sesión en estudio")
  add_media(album: a3, file: "imagen-14.jpg", title: "Colección verano", category: cats["Producto"])
  add_media(album: a3, file: "imagen-22.jpg", title: "Pastelería de autor", description: "Fotografía gastronómica para menú, redes y delivery.", category: cats["Producto"], featured: true)

  p4 = Project.create!(title: "Festival de música", category_label: "Cobertura de evento", featured: true, position: 4,
                       summary: "Cobertura con varias cámaras y aftermovie para redes.",
                       body: "Tres cámaras, dos días de festival y un aftermovie listo para compartir **al día siguiente**.\n\nTambién registramos el detrás de escena del equipo de producción.",
                       cover: media_file("img/imagen-15.jpg"), video: media_file("videos/festival.mp4"),
                       services: [svc["Producción audiovisual"], svc["Contenido para redes"]].compact)
  add_media(project: p4, file: "imagen-15.jpg", video: "festival.mp4", title: "Aftermovie del festival", description: "Resumen del evento editado para compartir al día siguiente.", category: cats["Eventos"], featured: true)
  a4 = Album.create!(project: p4, title: "La noche", description: "Luces, público y escenario.")
  add_media(album: a4, file: "imagen-18.jpg", video: "reel-marca.mp4", title: "Noche de luces", description: "Video corto para redes con ambiente nocturno y luces cálidas.", category: cats["Eventos"], featured: true)
  a5 = Album.create!(project: p4, title: "Detrás de cámara", description: "Así se ve un día de rodaje con el equipo de toma6.")
  add_media(album: a5, file: "imagen-21.jpg", title: "Nuestras cámaras", description: "Parte del equipo con el que trabajamos en cada rodaje.", category: cats["Backstage"], featured: true)
  add_media(album: a5, file: "imagen-25.jpg", video: "backstage.mp4", title: "Detrás de cámara", description: "Así se ve un día de rodaje con el equipo de toma6.", category: cats["Backstage"])

  Section.create!(page: "project", project: p4, kind: "quote", position: 3, theme: "red",
                  body: "En 24 horas teníamos el aftermovie en redes. Fue el video más compartido del festival.",
                  note: "Producción del festival")
  Section.create!(page: "project", project: p4, kind: "stats", position: 4, title: "El festival en cifras",
                  items: "3 | Cámaras\n2 | Días de rodaje\n24 h | Aftermovie publicado")

  p5 = Project.create!(title: "30 reels en 30 días", category_label: "Contenido para redes", featured: true, position: 5,
                       summary: "Contenido diario para una marca que quería crecer en redes.",
                       body: "Una jornada de grabación por semana para tener **contenido todos los días** durante un mes, con guiones, edición y versiones para cada red.",
                       cover: media_file("img/imagen-16.jpg"), services: [svc["Contenido para redes"], svc["Edición y postproducción"]].compact)
  a6 = Album.create!(project: p5, title: "Reels")
  add_media(album: a6, file: "imagen-28.jpg", video: "reel-vertical.mp4", title: "Reel de moda", description: "Contenido vertical para Instagram y TikTok.", category: cats["Retrato"], featured: true)
  add_media(album: a6, file: "imagen-17.jpg", title: "Luz de contra", description: "Retrato con luz de fondo para una campaña de marca personal.", category: cats["Retrato"], featured: true)

  # Álbum suelto de la galería (sin proyecto) y fotos sueltas
  paisajes = Album.create!(title: "Paisajes de El Salvador", description: "Banco de imágenes propio para turismo y marcas.")
  add_media(album: paisajes, file: "imagen-19.jpg", title: "Amanecer en la montaña", description: "Paisaje para contenido de turismo y banco de imágenes propio.", category: cats["Paisaje"], featured: true)
  add_media(album: paisajes, file: "imagen-27.jpg", title: "Cascadas del norte", description: "Fotografía de paisaje para campañas de turismo.", category: cats["Paisaje"])
  add_media(album: paisajes, file: "imagen-32.jpg", title: "Ciudad en movimiento", description: "Tomas urbanas para videos institucionales y de marca.", category: cats["Paisaje"])
  # Una misma foto en varias galerías: "Ciudad en movimiento" también es parte de "Oficios de la ciudad"
  MediaPlacement.attach!(MediaItem.find_by!(title: "Ciudad en movimiento"), p2)
  MediaPlacement.attach!(MediaItem.find_by!(title: "Nuestras cámaras"), a1)
  add_media(file: "imagen-23.jpg", title: "Boda en la ciudad", description: "Cobertura de ceremonia y fiesta, en foto y video.", category: cats["Eventos"], featured: true)
  add_media(file: "imagen-31.jpg", title: "Ceremonia", description: "Registro de eventos sociales y corporativos.", category: cats["Eventos"])
end

puts "→ Enlace con QR de ejemplo"
ShortLink.find_or_create_by!(code: "cotiza") do |l|
  l.title = "Flyer · Cotizá con toma6"
  l.destination_url = "/servicios#cotizador"
  l.utm_source = "flyer"
  l.utm_medium = "qr"
  l.qr_label = "Escaneá y cotizá"
end

puts "→ Cotización de ejemplo (podés eliminarla)"
if Quote.none?
  foto = Service.find_by(title: "Fotografía")
  video = Service.find_by(title: "Producción audiovisual")
  q = Quote.new(title: "Boda — cobertura completa", client_name: "Cliente de ejemplo", client_company: "Empresa de ejemplo",
                client_email: "cliente@ejemplo.com", event_date: 2.months.from_now.to_date, event_location: "San Salvador",
                tax_name: s.tax_name, tax_rate: s.tax_rate, discount_type: "percent", discount_value: 10,
                notes: s.quote_default_notes, terms: s.quote_default_terms, payment_info: s.quote_payment_info)
  q.items.build(service: video, description: "Producción audiovisual", details: "Ceremonia y fiesta, 2 cámaras", quantity: 1, unit_price: 700, position: 1)
  q.items.build(service: foto, description: "Fotografía", details: "Jornada completa, 400 fotos editadas", quantity: 1, unit_price: 480, position: 2)
  q.items.build(description: "Tomas con dron", details: "Sujeto a clima", quantity: 1, unit_price: 150, position: 3)
  q.save!
end

Current.reset
puts "✓ Listo. Entrá a /admin con #{admin.email}"
