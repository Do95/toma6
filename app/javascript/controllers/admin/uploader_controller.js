import { Controller } from "@hotwired/stimulus"
import { directUploadUrl, uploadDirect, videoInfo, shrinkImage } from "lib/media_upload"

// Subida masiva con arrastrar y soltar: muestra cada archivo con su barra de progreso
// y sube de a tres en paralelo.
//  - Fotos: se achican en el navegador (máx. 2800 px) antes de subir.
//  - Videos: suben directo a S3 (sin pasar por el servidor) y la portada es un cuadro del video.
const VIDEO_MAX = 400 * 1024 * 1024
const VIDEO_EXT = /\.(mp4|webm|mov|m4v)$/i

export default class extends Controller {
  static targets = ["input", "queue", "zone", "summary"]
  static values = { url: String }

  connect() {
    ["dragenter", "dragover"].forEach((e) => this.zoneTarget.addEventListener(e, (ev) => { ev.preventDefault(); this.zoneTarget.classList.add("is-over") }))
    ;["dragleave", "drop"].forEach((e) => this.zoneTarget.addEventListener(e, (ev) => { ev.preventDefault(); this.zoneTarget.classList.remove("is-over") }))
    this.zoneTarget.addEventListener("drop", (ev) => this.enqueue([...ev.dataTransfer.files]))
  }

  pick() { this.inputTarget.click() }

  chosen() {
    this.enqueue([...this.inputTarget.files])
    this.inputTarget.value = ""
  }

  enqueue(files) {
    const jobs = []
    files.forEach((file) => {
      if (file.type.startsWith("image/")) jobs.push({ file, kind: "photo", el: this.tile(file, "photo") })
      else if (file.type.startsWith("video/") || VIDEO_EXT.test(file.name)) jobs.push({ file, kind: "video", el: this.tile(file, "video") })
    })
    if (!jobs.length) return
    this.pending = (this.pending || []).concat(jobs)
    this.ok = this.ok || 0
    this.failed = this.failed || 0
    for (let i = 0; i < 3; i++) this.next()
  }

  tile(file, kind) {
    const el = document.createElement("div")
    el.className = `upload-item${kind === "video" ? " is-video" : ""}`
    el.innerHTML = `<img alt=""><span class="upload-label"></span><div class="bar"><span></span></div>`
    if (kind === "photo") el.querySelector("img").src = URL.createObjectURL(file)
    this.queueTarget.appendChild(el)
    return el
  }

  label(job, text) { job.el.querySelector(".upload-label").textContent = text }
  progress(job, ratio) { job.el.querySelector(".bar span").style.width = `${Math.round(ratio * 100)}%` }

  async next() {
    if (this.active >= 3) return
    const job = this.pending?.shift()
    if (!job) { if (!this.active) this.done(); return }
    this.active = (this.active || 0) + 1
    try {
      const form = new FormData()
      if (job.kind === "video") await this.prepareVideo(job, form)
      else {
        this.label(job, "Preparando…")
        form.append("files[]", await shrinkImage(job.file))
        this.label(job, "")
      }
      this.element.querySelectorAll("[data-upload-param]").forEach((el) => {
        form.append(el.name, el.type === "checkbox" ? (el.checked ? "1" : "0") : el.value)
      })
      await this.post(job, form)
      job.el.classList.add("is-done")
      this.ok++
    } catch (error) {
      job.el.classList.add("is-error")
      job.el.title = error.message
      this.label(job, "Error")
      this.failed++
    }
    this.active--
    this.next()
  }

  // Portada y duración desde el navegador; el video va directo a S3 si está configurado.
  async prepareVideo(job, form) {
    const file = job.file
    if (file.size > VIDEO_MAX) throw new Error(`${file.name}: pesa ${Math.round(file.size / 1048576)} MB, el máximo es 400 MB.`)
    this.label(job, "Leyendo video…")
    const info = await videoInfo(file)
    if (!info.poster) throw new Error(`${file.name}: no se pudo sacar una portada de este video. Subilo desde «Agregar video» y elegí una imagen.`)
    job.el.querySelector("img").src = URL.createObjectURL(info.poster)
    form.append("poster", info.poster)
    form.append("video_name", file.name)
    if (info.duration) form.append("duration", info.duration)
    if (directUploadUrl()) {
      this.label(job, "Subiendo 0%")
      const key = await uploadDirect(file, "video", (r) => { this.progress(job, r * 0.95); this.label(job, `Subiendo ${Math.round(r * 100)}%`) })
      form.append("video_key", key)
      this.label(job, "Guardando…")
      job.direct = true
    } else {
      form.append("video", file)
    }
  }

  post(job, form) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest()
      xhr.open("POST", this.urlValue)
      xhr.setRequestHeader("X-CSRF-Token", document.querySelector("meta[name='csrf-token']")?.content)
      xhr.setRequestHeader("Accept", "application/json")
      if (!job.direct) xhr.upload.onprogress = (e) => { if (e.lengthComputable) this.progress(job, e.loaded / e.total) }
      xhr.onload = () => {
        let errors = []
        try { errors = JSON.parse(xhr.responseText).errors || [] } catch (_) {}
        if (xhr.status >= 200 && xhr.status < 300 && !errors.length) { this.progress(job, 1); this.label(job, ""); resolve() }
        else reject(new Error(errors.join("\n") || `Error ${xhr.status}`))
      }
      xhr.onerror = () => reject(new Error("Se cortó la conexión."))
      xhr.send(form)
    })
  }

  done() {
    if (!this.hasSummaryTarget) return
    this.summaryTarget.hidden = false
    this.summaryTarget.querySelector("[data-count]").textContent =
      `${this.ok} ${this.ok === 1 ? "archivo subido" : "archivos subidos"}${this.failed ? ` · ${this.failed} con error (pasá el mouse por encima para ver el motivo)` : ""}`
  }

  reload() { window.Turbo ? Turbo.visit(window.location.href, { action: "replace" }) : window.location.reload() }
}
