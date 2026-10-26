source "https://rubygems.org"

ruby ">= 3.2.0" # Heroku usa la versión de .ruby-version / Gemfile.lock

gem "rails", "~> 8.0.2"
# json 3.0 (sept. 2026) rechaza la opción quirks_mode que Rails 8.0.5 todavía usa
# (ArgumentError: unknown keyword: quirks_mode). Rails ya lo corrigió en 8-0-stable;
# cuando salga la versión con el arreglo se puede quitar este límite.
gem "json", "~> 2.21"
gem "propshaft"
gem "pg", "~> 1.5"
gem "puma", ">= 6.4"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "bootsnap", require: false
gem "dotenv-rails" # lee el archivo .env
gem "tzinfo-data", platforms: %i[windows jruby]

# Autenticación y traducciones
gem "devise", "~> 4.9"
gem "devise-i18n"
gem "rails-i18n", "~> 8.0"

# URLs amigables con historial (las viejas redirigen)
gem "friendly_id", "~> 5.5"

# Archivos e imágenes (requiere ImageMagick en el servidor)
gem "carrierwave", "~> 3.1"
gem "mini_magick"
# Guardar fotos en S3 / R2 / Spaces (obligatorio en Heroku; se activa con S3_BUCKET)
gem "fog-aws", "~> 3.0", require: false

# Códigos QR (enlaces cortos)
gem "rqrcode_core", "~> 2.0"
gem "csv" # exportar e importar enlaces (en Ruby 3.4+ ya no viene incluido)

# PDF de cotizaciones
gem "prawn", "~> 2.5"
gem "prawn-table", "~> 0.2.2"

# Tareas en segundo plano y tareas programadas (purga de papelera, publicaciones)
gem "good_job", "~> 4.22"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

gem "pagy", "~> 43.0"

gem "redis", "~> 5.4"
