FriendlyId.defaults do |config|
  config.use :reserved
  # Palabras que no pueden ser slug porque chocan con rutas del sitio
  config.reserved_words = %w[new edit nuevo editar index admin assets uploads galeria albumes proyectos servicios cotizar]
  config.treat_reserved_as_conflict = true
end
