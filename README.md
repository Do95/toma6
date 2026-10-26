# toma6 · Sitio + panel de administración

Aplicación Ruby on Rails 8 con PostgreSQL que reemplaza la landing estática de toma6.
Todo lo que se ve en el sitio se administra desde `/admin`.

## Qué incluye

**Sitio público**
- Portada con el diseño actual (hero con diafragma, cintas, manifiesto, servicios animados, trabajos con scroll horizontal, galería, proceso, preguntas, contacto).
- `/proyectos` y `/proyectos/:slug`: página de cada proyecto con su historia, datos, video y galería con pestañas por álbum (Todo · General · cada álbum).
- `/galeria`: todas las fotos y videos (incluye los de los álbumes de cada proyecto), filtros por tipo, categoría y proyecto, y la fila de álbumes.
- `/galeria/albumes/:slug`: cada álbum.
- `/servicios#cotizador`: cotizador con precio en vivo, descuento por combo y envío de solicitud.
- `/c/:token`: enlace privado para que el cliente vea, descargue y acepte su cotización.
- `sitemap.xml` y `robots.txt` dinámicos.

**Panel (`/admin`)**
- **Secciones del inicio**: el inicio es una lista de secciones que se ordenan arrastrando, se ocultan, se duplican y se editan. Además de las fijas (portada, servicios, trabajos, galería, proceso, preguntas, contacto) podés agregar bloques: texto, texto con imagen, imagen grande, video (YouTube, Vimeo o archivo), llamado a la acción, testimonio, cifras, puntos destacados y galería de un álbum. Las que marques «en el menú» arman la barra de navegación.
- **Sección personalizada**: la armás vos con 1 a 4 columnas (o ancha + angosta). Cada columna lleva una ilustración de la marca o una foto, título, texto y enlace; se ordenan arrastrando. También hay un bloque de **código embebido** (Google Maps, Calendly, formularios), solo para administradores.
- **Ilustraciones de la marca**: 16 ilustraciones SVG animadas (cámara, claqueta, micrófono, dron, celular, luces, edición, calendario, mensajes, premio, ubicación…) en `app/models/illustrations.rb`. Se usan por defecto cuando una sección no tiene foto y se eligen con un selector visual.
- **Biblioteca de fotos**: cada foto vive una sola vez y puede estar en **varias galerías** (álbumes y la galería general de cada proyecto), con un orden propio en cada una. Desde un álbum o proyecto: «Elegir de la biblioteca»; desde una foto: «Aparece en». Si subís una foto que ya existe, no se duplica: se reutiliza. Quitar una foto de un álbum no la borra; eliminar un álbum tampoco borra sus fotos. La portada del álbum se elige desde la grilla.
- **Visor del sitio**: tira de miniaturas, «Aparece en» con enlaces a las otras galerías, enlace directo a cada foto (`/galeria#foto-12`) y precarga de la siguiente.
- **Enlaces y QR** (estilo Bitly): enlaces cortos propios (`toma6.com/l/codigo`) con QR de la marca (3 estilos, logo al centro, marco con texto), generados en el momento con Ruby (SVG y PNG de 1024 a 4096 px; no se guardan imágenes), exportar e importar enlaces en CSV, UTM para campañas, vencimiento y pausa. El destino se puede cambiar sin reimprimir el QR. Estadísticas por enlace: visitas por QR y por enlace, visitantes únicos, dispositivos y origen; no se guarda la IP y los bots/vistas previas no cuentan.
- **URLs amigables** (friendly_id): `/proyectos/quinceanos-de-sofia`. Si cambiás el título, la URL vieja redirige (301) a la nueva; si se repite queda `-2`. El slug también se puede escribir a mano.
- **Secciones de cada proyecto**: la página de cada proyecto se arma igual (historia, galería y los bloques que quieras), desde la pestaña *Secciones de la página* del proyecto.
- **Datos del sitio** (identidad, contacto, redes, logos, SEO), servicios con opciones de precio, proyectos, álbumes, galería con subida masiva, categorías, proceso, preguntas y valores. Todo ordenable arrastrando.
- Solicitudes del cotizador → se convierten en cotización con un clic. Cada solicitud tiene su código automático (SOL-2026-0001) que el cliente ve en la confirmación y en su correo.
- **Numeración automática de cotizaciones** (COT-2026-0001): prefijo, dígitos, con o sin año y número inicial configurables en *Ajustes*. Nunca se repite (ni con las de la papelera) aunque varias personas guarden a la vez.
- Cotizaciones con PDF de la marca, envío por correo con el PDF adjunto, enlace público, duplicar y estados.
- Publicaciones para Facebook e Instagram (se desbloquean al conectar la integración; ver abajo).
- Usuarios con roles: **Administrador**, **Editor de contenido**, **Ventas**, **Solo lectura**.
- **Auditoría**: cada registro guarda quién lo creó, quién lo modificó y quién lo eliminó; la sección *Actividad* muestra cada cambio (antes → después), filtrable por persona, acción y tipo.
- **Confirmaciones con modal**: guardar cambios (muestra qué campos cambiaron), eliminar, eliminar definitivamente, salir con cambios sin guardar y acciones en lote. Sin ventanas del navegador.
- **Eliminar definitivamente**: además de la papelera, los administradores pueden borrar al instante (con sus archivos), desde la ficha o en lote en la biblioteca. Queda en la bitácora.
- **Carga y errores**: skeleton mientras cargan fotos, QR y PDF; si una imagen no carga o no existe se muestra una ilustración de la marca. Estados vacíos con ilustración (por ejemplo, un inicio sin secciones) y botón para restaurar las secciones fijas.
- **Papelera** (borrado lógico): todo lo eliminado se puede restaurar. Una tarea diaria (3:00) borra definitivamente, con sus archivos, lo que lleva más de **15 días** en la papelera (configurable en *Ajustes*). Un administrador también puede vaciarla a mano.

## Requisitos

- Ruby 3.3, PostgreSQL 14+ e ImageMagick (para las miniaturas de las fotos). Los PNG de los QR se generan en Ruby puro: no necesitan nada instalado.
- No requiere Node: el JavaScript usa importmap.

## Instalación local

```bash
cp .env.example .env        # completá usuario/clave de Postgres
bin/setup                   # instala gemas, crea la base y carga el contenido actual
bin/dev                     # http://localhost:3000
```

Panel: http://localhost:3000/admin — usuario `ADMIN_EMAIL` / `ADMIN_PASSWORD` del `.env`
(por defecto `admin@toma6.com` / `cambiame-ya-123`). Cambiá la contraseña en *Mi perfil*.

Los correos en desarrollo se abren en el navegador (letter_opener).

## Producción

> **Importante:** el hosting compartido de Hostinger (el de `public_html`) no ejecuta Rails.
> Se necesita un **VPS** (por ejemplo el VPS de Hostinger con Ubuntu 24.04) o un servicio
> como Render o Railway.

En un VPS con Ubuntu:

```bash
sudo apt install -y postgresql libpq-dev imagemagick nginx certbot python3-certbot-nginx build-essential libyaml-dev
# instalar Ruby 3.3 con rbenv o mise
git clone … /home/deploy/toma6 && cd /home/deploy/toma6
cp .env.example .env   # completá todo; SECRET_KEY_BASE con: bin/rails secret
bin/rails db:encryption:init   # copiá las 3 claves al .env (AR_ENCRYPTION_*)
bundle config set --local without 'development test'
bundle install
RAILS_ENV=production bin/rails db:prepare assets:precompile
sudo cp config/deploy/toma6.service /etc/systemd/system/ && sudo systemctl enable --now toma6
sudo cp config/deploy/nginx.conf /etc/nginx/sites-available/toma6 && sudo ln -s ../sites-available/toma6 /etc/nginx/sites-enabled/
sudo certbot --nginx -d toma6.com -d www.toma6.com
```

Para revisar que el servidor pueda generar los PNG de los QR: `bin/rails qr:check`.

Las tareas programadas (purga de papelera y publicaciones programadas) corren **dentro del mismo proceso de Puma** (GoodJob en modo async): no hay que configurar cron ni workers. Se pueden ver en `/admin/tareas` (solo administradores).
Si preferís cron, también existe `bin/rails trash:purge`.

Las fotos y videos se guardan en `public/uploads`. Incluí esa carpeta en tus respaldos
(o activá S3/Spaces en `config/initializers/carrierwave.rb`).

## Correos

Los correos automáticos tienen **plantillas editables** en *Correos → Plantillas* (asunto, título, texto, botón y destinatarios del equipo), con variables como `{{primer_nombre}}` o `{{total_estimado}}`, vista previa y botón «Enviarme una prueba»:

- Solicitud recibida (al cliente) y Nueva solicitud (al equipo)
- Cotización enviada (al cliente, con el PDF adjunto)
- Cotización aceptada (al cliente y al equipo)

Todos los envíos, incluidos los de recuperar contraseña, quedan en *Correos → Historial* con su estado. Se envían en segundo plano: **la solicitud siempre se guarda primero y el cliente siempre ve su confirmación**, aunque el servidor de correo falle. Si un correo falla se reintenta solo (a los 2 y a los 15 minutos); si sigue fallando queda como «Falló» con el error, aparece un aviso en el inicio del panel y se puede reenviar con un clic cuando el SMTP vuelva a funcionar.

## Fotos en S3

Todas las fotos, videos y logos que se suben desde el panel se guardan en un bucket de
**Amazon S3** (o compatible: Cloudflare R2, DigitalOcean Spaces, Backblaze B2).
En producción es obligatorio: si faltan las variables, la app no arranca y dice cuáles.
En desarrollo, sin `S3_BUCKET`, se guardan en `public/uploads`.

### 1. Crear el bucket (AWS)

1. S3 → **Create bucket**, por ejemplo `toma6-fotos`, región `us-east-1`.
2. *Object Ownership*: dejá **ACLs disabled** (lo recomendado).
3. *Block Public Access*: destildá **solo** «Block public access … through *new* public bucket or access point policies» y «… through *any* public bucket or access point policies». Las dos de ACL pueden quedar tildadas.
4. Pestaña **Permissions → Bucket policy**: pegá esto (cambiá el nombre del bucket). Solo hace pública la carpeta `uploads/`:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "LecturaPublicaDeFotos",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::toma6-fotos/uploads/*"
  }]
}
```

### 2. Usuario con acceso solo a ese bucket (IAM)

IAM → Users → **Create user** `toma6-app` → *Attach policies directly* → *Create policy* (JSON):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"], "Resource": "arn:aws:s3:::toma6-fotos/*" },
    { "Effect": "Allow", "Action": ["s3:ListBucket"], "Resource": "arn:aws:s3:::toma6-fotos" }
  ]
}
```

Después: el usuario → *Security credentials* → **Create access key** (tipo «Application running outside AWS»).

### 3. Variables

```bash
S3_BUCKET=toma6-fotos
S3_ACCESS_KEY_ID=AKIA…
S3_SECRET_ACCESS_KEY=…
S3_REGION=us-east-1
# Opcional: dominio o CDN delante del bucket (CloudFront, Cloudflare)
S3_PUBLIC_URL=https://fotos.toma6.com
```

Para R2/Spaces/B2 agregá `S3_ENDPOINT` (y `S3_PATH_STYLE=true` si el proveedor lo pide).
Si tu bucket usa ACL (buckets viejos) en lugar de política, definí `S3_OBJECT_ACL=public-read`.

### 4. Probar y pasar las fotos que ya tenés

```bash
bin/rails uploads:check     # sube un archivo de prueba, verifica que se vea públicamente y lo borra
bin/rails uploads:to_s3     # copia todo lo de public/uploads al bucket, con las mismas rutas
```

`uploads:to_s3` se puede correr más de una vez: lo que ya está en el bucket no se vuelve a subir.

### 5. Subida directa de videos (CORS)

Los videos (hasta 400 MB) suben **directo del navegador a S3**: no pasan por el servidor, así que
no chocan con el límite de 30 s ni con la memoria del dyno de Heroku. El panel pide una URL firmada
(válida 15 minutos), sube a `uploads/direct/…` y, al guardar, el servidor lo copia dentro de S3 a su
carpeta definitiva. La portada es un cuadro del video (si no elegís una) y la duración se completa sola.
Las fotos se achican en el navegador a 2800 px antes de subir.

Para que el navegador pueda subir, el bucket necesita **CORS** (S3 → bucket → *Permissions* → *CORS*):

```json
[{
  "AllowedOrigins": ["https://www.toma6.com", "https://toma6.com", "http://localhost:3000"],
  "AllowedMethods": ["PUT"],
  "AllowedHeaders": ["Content-Type", "x-amz-acl"],
  "ExposeHeaders": ["ETag"],
  "MaxAgeSeconds": 3600
}]
```

Recomendado: una regla de ciclo de vida (*Management → Lifecycle rules*) que borre lo que quede en
`uploads/direct/` después de 1 día (subidas que alguien empezó y no guardó).

Sin S3 (desarrollo con `public/uploads`) la subida directa no se activa y todo sube como siempre.

## Heroku

El proyecto ya trae `Procfile` (web + migraciones en cada deploy) y `app.json`, preparado para el stack
**heroku-26** (Ubuntu 26.04). Probado en la imagen oficial `heroku/heroku:26-build` (amd64 y arm64): Ruby 3.3.6,
gemas nativas, ImageMagick 7 (miniaturas) y assets.

En cada deploy, la fase de release corre las migraciones y `bin/rails toma6:check_image_tools`: si ImageMagick
no procesa imágenes en el stack, el deploy se frena y queda la versión anterior.

> Las fotos van a S3 (ver «Fotos en S3»): configurá el bucket antes del primer deploy.

```bash
# 1. El Gemfile.lock ya incluye las plataformas de Heroku (x86_64-linux y aarch64-linux)

# 2. Crear la app con Postgres en heroku-26
heroku create toma6 --stack heroku-26
heroku addons:create heroku-postgresql:essential-0

# 3. Variables
heroku config:set RAILS_ENV=production APP_HOST=www.toma6.com APP_PROTOCOL=https \
  SECRET_KEY_BASE=$(bin/rails secret) \
  AR_ENCRYPTION_PRIMARY_KEY=$(bin/rails secret) AR_ENCRYPTION_DETERMINISTIC_KEY=$(bin/rails secret) \
  AR_ENCRYPTION_KEY_DERIVATION_SALT=$(bin/rails secret) \
  S3_BUCKET=toma6-fotos S3_ACCESS_KEY_ID=… S3_SECRET_ACCESS_KEY=… S3_REGION=us-east-1 \
  ADMIN_EMAIL=admin@toma6.com ADMIN_PASSWORD=una-clave-segura \
  SMTP_ADDRESS=… SMTP_USERNAME=… SMTP_PASSWORD=… MAIL_FROM="toma6 <hola@toma6.com>"

# 4. Deploy y contenido inicial
git push heroku main
heroku run bin/rails db:seed

# 5. Dominio
heroku domains:add www.toma6.com
```

Para Cloudflare R2 o DigitalOcean Spaces agregá también `S3_ENDPOINT` (y `S3_PATH_STYLE=true` si el proveedor lo pide).

**Tareas en segundo plano:** están en pausa por defecto (`JOBS_ENABLED=false`): GoodJob no arranca y los correos se envían en memoria, dentro del mismo proceso. Para la purga de la papelera y los posts programados usá Heroku Scheduler con `bin/rails trash:purge` (diario) y `bin/rails social:publish_scheduled` (cada 10 minutos). Con `JOBS_ENABLED=true` vuelve GoodJob con su cron y su panel en `/admin/tareas`.

**Tareas programadas (con GoodJob):** la purga de la papelera y las publicaciones programadas corren dentro del dyno web. Con planes que se "duermen" (Eco), conviene agregar **Heroku Scheduler** con `bin/rails trash:purge` una vez por día.

**Pasar una app existente a heroku-26:**

```bash
heroku stack:set heroku-26 -a toma6
git commit --allow-empty -m "Rebuild en heroku-26" && git push heroku main   # el cambio de stack se aplica en el próximo build
```

Si algo falla, `heroku stack:set heroku-24` y otro push vuelven al stack anterior.

**Caché (opcional, recomendado):** con un Redis (`heroku addons:create heroku-redis:mini`) el caché de las páginas se
comparte entre dynos y sobrevive a los deploys; sin Redis usa la memoria del dyno. Para que la clave cambie con cada
deploy usando el commit: `heroku labs:enable runtime-dyno-metadata`.

**QR:** los PNG se generan en Ruby puro, sin librerías del sistema; `heroku run bin/rails qr:check` genera uno de prueba.

## Facebook e Instagram (opcional)

1. En **developers.facebook.com** creá una app de tipo *Empresa* y agregá *Inicio de sesión con Facebook* e *Instagram*.
2. En «URI de redireccionamiento de OAuth válidos» pegá la URL que muestra el panel en *Integraciones* (`https://SU-DOMINIO/admin/integraciones/callback`).
3. En el panel → *Integraciones*: pegá App ID y App Secret → *Conectar con Facebook* → elegí la página.
4. Si la cuenta de Instagram es profesional y está vinculada a esa página, se activa también.

Hasta que no se conecte, el menú *Publicaciones* aparece con candado y el resto del panel funciona normal.
Instagram descarga la foto desde tu dominio, así que solo funciona con el sitio publicado (no en `localhost`) y con *Dominio del sitio* completo en *Contenido del sitio → SEO*.

## Roles

| Rol | Puede |
| --- | --- |
| Administrador | Todo: usuarios, ajustes, integraciones, vaciar papelera, tareas. |
| Editor de contenido | Crear, editar y eliminar contenido del sitio y publicaciones; ver ventas. |
| Ventas | Solicitudes y cotizaciones; ver el contenido sin editarlo. |
| Solo lectura | Ver todo el panel sin cambiar nada. |

La matriz está en `app/models/permissions.rb`.

## Formato de textos

En los textos largos del panel se puede usar `**negrita**`, `==resaltado rojo==` y una línea vacía para separar párrafos.

## Estructura

- `app/models/concerns/auditable.rb`, `soft_deletable.rb`: auditoría y papelera.
- `app/services/trash_purger.rb`, `app/jobs/purge_trash_job.rb`: limpieza de papelera.
- `app/services/quote_estimator.rb`: cálculo del cotizador (el servidor recalcula todo).
- `app/pdfs/quote_pdf.rb`: PDF de cotización (tipografía Archivo en `vendor/fonts`, licencia OFL).
- `app/services/meta/client.rb`, `social_publisher.rb`: integración con Meta.
- `config/initializers/load_routes.rb`: hace que el login funcione desde la primera visita en Rails 8.
- `db/seeds.rb`: contenido inicial (el sitio actual). Los precios del cotizador son de ejemplo: ajustalos en *Servicios*.
