import { Controller } from "@hotwired/stimulus"

// Subida masiva con arrastrar y soltar: muestra cada foto con su barra de progreso
// y la sube de a tres en paralelo.
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
    const images = files.filter((f) => f.type.startsWith("image/"))
    if (!images.length) return
    this.pending = (this.pending || []).concat(images.map((file) => ({ file, el: this.tile(file) })))
    this.ok = this.ok || 0
    this.failed = this.failed || 0
    for (let i = 0; i < 3; i++) this.next()
  }

  tile(file) {
    const el = document.createElement("div")
    el.className = "upload-item"
    el.innerHTML = `<img alt=""><div class="bar"><span></span></div>`
    el.querySelector("img").src = URL.createObjectURL(file)
    this.queueTarget.appendChild(el)
    return el
  }

  next() {
    if (this.active >= 3) return
    const job = this.pending?.shift()
    if (!job) { if (!this.active) this.done(); return }
    this.active = (this.active || 0) + 1
    const form = new FormData()
    form.append("files[]", job.file)
    this.element.querySelectorAll("[data-upload-param]").forEach((el) => {
      const value = el.type === "checkbox" ? (el.checked ? "1" : "0") : el.value
      form.append(el.name, value)
    })
    const xhr = new XMLHttpRequest()
    xhr.open("POST", this.urlValue)
    xhr.setRequestHeader("X-CSRF-Token", document.querySelector("meta[name='csrf-token']")?.content)
    xhr.setRequestHeader("Accept", "application/json")
    xhr.upload.onprogress = (e) => { if (e.lengthComputable) job.el.querySelector(".bar span").style.width = `${(e.loaded / e.total) * 100}%` }
    xhr.onload = () => {
      const ok = xhr.status >= 200 && xhr.status < 300
      job.el.classList.add(ok ? "is-done" : "is-error")
      if (!ok) {
        try { job.el.title = JSON.parse(xhr.responseText).errors.join("\n") } catch (_) {}
      }
      ok ? this.ok++ : this.failed++
      this.active--
      this.next()
    }
    xhr.onerror = () => { job.el.classList.add("is-error"); this.failed++; this.active--; this.next() }
    xhr.send(form)
  }

  done() {
    if (!this.hasSummaryTarget) return
    this.summaryTarget.hidden = false
    this.summaryTarget.querySelector("[data-count]").textContent =
      `${this.ok} ${this.ok === 1 ? "foto subida" : "fotos subidas"}${this.failed ? ` · ${this.failed} con error (pasá el mouse por encima para ver el motivo)` : ""}`
  }

  reload() { window.Turbo ? Turbo.visit(window.location.href, { action: "replace" }) : window.location.reload() }
}
