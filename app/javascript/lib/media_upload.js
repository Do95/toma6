// Herramientas de subida del panel:
//  - uploadDirect: sube un archivo directo a S3 con una URL firmada (sin pasar por el servidor)
//  - videoInfo: saca un cuadro del video como portada y su duración
//  - shrinkImage: achica fotos grandes en el navegador antes de subirlas (máx. 2800 px, como el servidor)

const MAX_SIDE = 2800

// La subida directa está activa solo si el servidor usa S3 (meta en el layout del panel)
export function directUploadUrl() {
  return document.querySelector("meta[name='direct-upload-url']")?.content || null
}

function csrf() { return document.querySelector("meta[name='csrf-token']")?.content }

// Devuelve la clave del archivo en S3. Rechaza con un mensaje en castellano.
export async function uploadDirect(file, kind, onProgress = () => {}) {
  const res = await fetch(directUploadUrl(), {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf(), Accept: "application/json" },
    body: JSON.stringify({ filename: file.name, content_type: file.type || "application/octet-stream", size: file.size, kind })
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(data.error || "No se pudo preparar la subida.")

  await new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest()
    xhr.open("PUT", data.url)
    Object.entries(data.headers || {}).forEach(([k, v]) => xhr.setRequestHeader(k, v))
    xhr.upload.onprogress = (e) => { if (e.lengthComputable) onProgress(e.loaded / e.total) }
    xhr.onload = () => (xhr.status >= 200 && xhr.status < 300 ? resolve() : reject(new Error(`S3 rechazó la subida (${xhr.status}). Revisá la configuración CORS del bucket.`)))
    xhr.onerror = () => reject(new Error("Se cortó la conexión con S3. Revisá tu internet o la configuración CORS del bucket."))
    xhr.send(file)
  })
  onProgress(1)
  return data.key
}

// Portada (JPEG de un cuadro cerca del comienzo) y duración "m:ss". Si el navegador no puede
// leer el video (por ejemplo HEVC en algunos equipos), devuelve poster: null.
export function videoInfo(file) {
  return new Promise((resolve) => {
    const url = URL.createObjectURL(file)
    const video = document.createElement("video")
    let done = false
    const finish = (out) => { if (done) return; done = true; URL.revokeObjectURL(url); resolve(out) }
    const timer = setTimeout(() => finish({ poster: null, duration: null }), 10000)
    video.muted = true
    video.playsInline = true
    video.preload = "auto"
    video.src = url
    video.onerror = () => { clearTimeout(timer); finish({ poster: null, duration: null }) }
    video.onloadedmetadata = () => {
      video.currentTime = Math.min(1, (video.duration || 0) * 0.1)
    }
    video.onseeked = () => {
      const duration = formatDuration(video.duration)
      const w = video.videoWidth, h = video.videoHeight
      if (!w || !h) { clearTimeout(timer); finish({ poster: null, duration }); return }
      const scale = Math.min(1, 1600 / Math.max(w, h))
      const canvas = document.createElement("canvas")
      canvas.width = Math.round(w * scale)
      canvas.height = Math.round(h * scale)
      canvas.getContext("2d").drawImage(video, 0, 0, canvas.width, canvas.height)
      canvas.toBlob((blob) => {
        clearTimeout(timer)
        const name = file.name.replace(/\.[^.]+$/, "") + "-portada.jpg"
        finish({ poster: blob ? new File([blob], name, { type: "image/jpeg" }) : null, duration })
      }, "image/jpeg", 0.86)
    }
  })
}

export function formatDuration(seconds) {
  if (!Number.isFinite(seconds) || seconds <= 0) return null
  const s = Math.round(seconds)
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60
  return h ? `${h}:${String(m).padStart(2, "0")}:${String(r).padStart(2, "0")}` : `${m}:${String(r).padStart(2, "0")}`
}

// Fotos de celular o dron (12–25 MB) bajan a 1–3 MB: suben mucho más rápido y el servidor
// procesa las miniaturas sin quedarse sin memoria. Si no conviene, devuelve el archivo tal cual.
export async function shrinkImage(file) {
  if (!/^image\/(jpeg|png|webp)$/.test(file.type) || typeof createImageBitmap !== "function") return file
  let bitmap
  try { bitmap = await createImageBitmap(file, { imageOrientation: "from-image" }) } catch (_) { return file }
  const { width, height } = bitmap
  if (Math.max(width, height) <= MAX_SIDE && file.size < 3 * 1024 * 1024) { bitmap.close?.(); return file }
  const scale = Math.min(1, MAX_SIDE / Math.max(width, height))
  const canvas = document.createElement("canvas")
  canvas.width = Math.round(width * scale)
  canvas.height = Math.round(height * scale)
  canvas.getContext("2d").drawImage(bitmap, 0, 0, canvas.width, canvas.height)
  bitmap.close?.()
  const type = file.type === "image/png" ? "image/png" : "image/jpeg"
  const blob = await new Promise((r) => canvas.toBlob(r, type, 0.9))
  if (!blob || blob.size >= file.size) return file
  const name = type === "image/jpeg" ? file.name.replace(/\.(png|webp|jpe?g)$/i, "") + ".jpg" : file.name
  return new File([blob], name, { type, lastModified: file.lastModified })
}
