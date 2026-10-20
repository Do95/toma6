import { Controller } from "@hotwired/stimulus"
import { directUploadUrl, uploadDirect, videoInfo } from "lib/media_upload"

// Formulario de un video: al elegirlo se arma la portada con un cuadro del video (si no
// hay una), se completa la duración y el archivo sube directo a S3 con su progreso.
// El formulario manda solo la clave del archivo: el video nunca pasa por el servidor.
const VIDEO_MAX = 400 * 1024 * 1024

export default class extends Controller {
  static targets = ["file", "key", "status", "duration"]

  connect() {
    this.onSubmit = (e) => {
      if (!this.uploading) return
      e.preventDefault()
      e.stopImmediatePropagation()
      this.say("Esperá a que termine de subir el video…", "warn")
    }
    this.element.addEventListener("submit", this.onSubmit, true)
    if (this.keyTarget.value) this.say("El video ya está subido. Guardá para terminar.", "ok", 1)
  }

  disconnect() { this.element.removeEventListener("submit", this.onSubmit, true) }

  async chosen() {
    const file = this.fileTarget.files[0]
    if (!file) return
    if (file.size > VIDEO_MAX) {
      this.fileTarget.value = ""
      this.say(`Pesa ${Math.round(file.size / 1048576)} MB y el máximo es 400 MB. Exportalo más liviano o subilo a YouTube/Vimeo.`, "error")
      return
    }
    this.keyTarget.value = ""
    this.say("Leyendo el video…", "", 0)
    const info = await videoInfo(file)
    if (info.duration && this.hasDurationTarget && !this.durationTarget.value) this.durationTarget.value = info.duration
    const title = this.element.querySelector("input[name$='[title]']")
    if (title && !title.value) title.value = file.name.replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ").replace(/\s+/g, " ").trim().replace(/^./, (c) => c.toUpperCase())

    // Portada automática, solo si todavía no hay una
    const imageInput = this.element.querySelector("input[type=file][name$='[image]']")
    const field = imageInput?.closest(".image-field")
    const hasImage = imageInput?.files.length > 0 || !!field?.querySelector("img.preview:not(.is-empty)")
    if (!hasImage && info.poster && imageInput) {
      const dt = new DataTransfer()
      dt.items.add(info.poster)
      imageInput.files = dt.files
      // La vista previa escucha «input»; «change» es para el aviso de cambios sin guardar
      imageInput.dispatchEvent(new Event("input", { bubbles: true }))
      imageInput.dispatchEvent(new Event("change", { bubbles: true }))
    }
    const noPoster = !hasImage && !info.poster
    const posterNote = noPoster ? " Falta la portada: este video no se pudo leer en el navegador, elegí una imagen." : ""

    if (!directUploadUrl()) { this.say(`Listo para guardar.${posterNote}`, noPoster ? "warn" : "ok", 1); return }

    this.uploading = true
    this.lockSubmit(true)
    try {
      const key = await uploadDirect(file, "video", (r) => this.say(`Subiendo a S3… ${Math.round(r * 100)}%`, "", r))
      this.keyTarget.value = key
      this.fileTarget.value = "" // ya está en S3: no se vuelve a mandar con el formulario
      this.say(`Video subido. Ya podés guardar.${posterNote}`, noPoster ? "warn" : "ok", 1)
    } catch (error) {
      this.say(error.message, "error")
    } finally {
      this.uploading = false
      this.lockSubmit(false)
    }
  }

  lockSubmit(on) {
    this.element.querySelectorAll("button[type=submit], input[type=submit]").forEach((b) => { b.disabled = on })
  }

  say(text, tone = "", ratio = null) {
    const box = this.statusTarget
    box.hidden = false
    box.className = `upload-status${tone ? ` is-${tone}` : ""}`
    box.querySelector("p").textContent = text
    const bar = box.querySelector(".bar")
    bar.hidden = ratio === null
    if (ratio !== null) bar.querySelector("span").style.width = `${Math.round(ratio * 100)}%`
  }
}
