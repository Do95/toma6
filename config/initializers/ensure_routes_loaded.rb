# Rails 8 carga las rutas recién cuando se necesitan. Devise configura el login
# (Warden) al cargarlas, así que si la primera visita era justo «Ingresar», el
# login fallaba. Este middleware se asegura de que las rutas estén cargadas antes
# de que Warden atienda cada request (no cuesta nada si ya lo están).
#
# Antes se hacía al terminar de arrancar la app, pero tocar las rutas durante el
# arranque podía chocar con la carga de código (Zeitwerk::SetupRequired).
class EnsureRoutesLoaded
  def initialize(app)
    @app = app
  end

  def call(env)
    app = Rails.application
    app.reload_routes_unless_loaded if app.respond_to?(:reload_routes_unless_loaded)
    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before Warden::Manager, EnsureRoutesLoaded
