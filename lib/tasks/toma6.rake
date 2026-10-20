namespace :trash do
  desc "Borra definitivamente lo que superó los días de retención en la papelera"
  task purge: :environment do
    result = TrashPurger.call
    puts "Eliminados definitivamente: #{result.total} #{result.counts.inspect}"
  end
end

namespace :toma6 do
  desc "Crea un usuario administrador: bin/rails toma6:admin EMAIL=ana@toma6.com NAME='Ana' PASSWORD=..."
  task admin: :environment do
    email = ENV.fetch("EMAIL") { abort "Indicá EMAIL=..." }
    password = ENV["PASSWORD"].presence || SecureRandom.alphanumeric(14)
    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(name: ENV.fetch("NAME", email.split("@").first.capitalize), role: "admin", active: true, password: password)
    user.save!
    puts "Administrador listo: #{email} / #{password}"
  end
end

namespace :qr do
  desc "Genera un QR de prueba en PNG (Ruby puro, sin dependencias del sistema)"
  task check: :environment do
    t = Time.current
    png = QrPng.render(size: 1024, text: "https://www.toma6.com/l/prueba?s=qr", label: "Prueba")
    File.binwrite(Rails.root.join("tmp/qr-prueba.png"), png)
    puts "✓ PNG de #{png.bytesize / 1024} KB en #{(Time.current - t).round(2)} s → tmp/qr-prueba.png"
  end
end

namespace :social do
  desc "Publica los posts programados que ya llegaron a su hora (para Heroku Scheduler o cron si JOBS_ENABLED=false)"
  task publish_scheduled: :environment do
    due = SocialPost.kept.where(status: "scheduled").where(scheduled_at: ..Time.current)
    due.find_each { |post| PublishSocialPostJob.perform_now(post.id, post.created_by_id) }
    puts "Publicaciones procesadas: #{due.count}"
  end
end

namespace :uploads do
  desc "Prueba S3: sube un archivo, verifica que se pueda ver públicamente y lo borra"
  task check: :environment do
    unless UploadsStorage.s3?
      puts "✗ S3 no está configurado: las fotos se guardan en el disco (public/uploads). Definí S3_BUCKET y las claves."
      next
    end
    require "net/http"
    storage = Fog::Storage.new(CarrierWave::Uploader::Base.fog_credentials)
    dir = storage.directories.new(key: ENV["S3_BUCKET"])
    key = "uploads/_prueba/#{SecureRandom.hex(6)}.txt"
    print "Subiendo #{key}… "
    file = dir.files.create(key: key, body: "toma6 ok", content_type: "text/plain")
    puts "OK"
    url = UploadsStorage.public_url_for(key)
    res = Net::HTTP.get_response(URI(url))
    if res.code == "200"
      puts "✓ Lectura pública OK: #{url}"
    else
      puts "✗ El archivo se subió pero no se puede ver públicamente (HTTP #{res.code})."
      puts "  Agregá al bucket la política de lectura pública para uploads/* (README → «Fotos en S3»)."
    end
    file.destroy
    puts "Archivo de prueba borrado."
  end

  # Las fotos de muestra (db/seeds/media) se guardan como "<token>-imagen-12.jpg": por ese nombre se
  # reconocen y se vuelven a subir desde la carpeta de semillas. Las fotos que subieron desde el panel
  # no se tocan. Sirve para reponer archivos perdidos o para cambiar las de muestra por versiones más
  # grandes (reemplazá el archivo en db/seeds/media/img con el mismo nombre y corré la tarea).
  desc "Vuelve a subir las fotos de muestra sin borrar datos: bin/rails uploads:replace_defaults [DRY_RUN=1] [MISSING=1]"
  task replace_defaults: :environment do
    mounts = { MediaItem => %i[image video], Project => %i[cover video], Album => %i[cover], Service => %i[image image_secondary image_tertiary],
               Section => %i[image video], SectionBlock => %i[image], SiteSetting => %i[og_image] }
    sources = Dir.glob(Rails.root.join("db/seeds/media/{,img/,videos/}*.{jpg,jpeg,png,webp,mp4}"))
                 .reject { |f| File.basename(f).start_with?("logo-") } # los logos se suben desde Datos del sitio
                 .index_by { |f| File.basename(f, ".*") }
    names = sources.keys.map { |n| Regexp.escape(n) }.join("|")
    seed_name = /\A\h{8}-(#{names})\.\w+\z/
    dry = ENV["DRY_RUN"] == "1"
    only_missing = ENV["MISSING"] == "1"
    replaced = skipped = 0

    mounts.each do |model, columns|
      columns.each do |column|
        model.where("#{column} ~ ?", "^[0-9a-f]{8}-(#{names})\\.").find_each do |record|
          base = record.public_send(:"#{column}_identifier").to_s[seed_name, 1]
          source = sources[base]
          next puts("  ✗ #{model.name} ##{record.id} #{column}: falta db/seeds/media/…/#{base}.*") unless source
          if only_missing && record.public_send(column).file&.exists?
            skipped += 1
            next
          end
          puts "  #{dry ? '·' : '✓'} #{model.name} ##{record.id} #{column} ← #{Pathname(source).relative_path_from(Rails.root)}"
          next if dry
          File.open(source) { |io| record.public_send(:"#{column}=", io) }
          record.save!(validate: false) # solo cambia el archivo: no lo frena un dato viejo de otro campo
          replaced += 1
        end
      end
    end
    puts dry ? "Simulación: no se cambió nada." : "✓ Fotos reemplazadas: #{replaced}#{" · ya estaban: #{skipped}" if only_missing}"
  end

  desc "Copia al bucket todas las fotos que hoy están en public/uploads (mismas rutas: no se rompe ningún enlace)"
  task to_s3: :environment do
    abort "Primero configurá S3 (S3_BUCKET y las claves)." unless UploadsStorage.s3?
    root = Rails.root.join("public")
    files = Dir.glob(root.join("uploads/**/*")).select { |f| File.file?(f) }
    abort "No hay archivos en public/uploads." if files.empty?
    storage = Fog::Storage.new(CarrierWave::Uploader::Base.fog_credentials)
    dir = storage.directories.new(key: ENV["S3_BUCKET"])
    force = ENV["FORCE"] == "1"
    copied = skipped = 0
    files.each_with_index do |path, i|
      key = Pathname(path).relative_path_from(root).to_s
      if !force && dir.files.head(key)
        skipped += 1
      else
        File.open(path, "rb") do |io|
          attrs = { key: key, body: io, content_type: Marcel::MimeType.for(Pathname(path)), "Cache-Control" => "public, max-age=31536000, immutable" }
          attrs[:public] = true if ENV["S3_OBJECT_ACL"] == "public-read"
          dir.files.create(attrs)
        end
        copied += 1
      end
      print "\r#{i + 1}/#{files.size} · copiados #{copied} · ya estaban #{skipped}"
    end
    puts "\n✓ Listo. Ahora las fotos se sirven desde el bucket. Podés borrar public/uploads cuando verifiques el sitio."
  end
end
