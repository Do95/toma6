import { Controller } from "@hotwired/stimulus"
import { shrinkImage } from "lib/media_upload"

export default class extends Controller {
  static targets = ["preview", "file"]

  async show(event) {
    const input = event.target
    let file = input.files?.[0]
    if (!file || !file.type.startsWith("image/")) return
    // Fotos enormes (celular, dron) se achican antes de subir: el formulario viaja liviano
    const small = await shrinkImage(file)
    if (small !== file && input.files?.[0] === file) {
      const dt = new DataTransfer()
      dt.items.add(small)
      input.files = dt.files
      file = small
    }
    // Una foto subida reemplaza a la elegida de la galería
    this.element.querySelectorAll(".library input[type=radio]").forEach((r) => { r.checked = r.value === "" })
    this.setPreview(URL.createObjectURL(file))
    const cta = this.element.querySelector(".dz-cta")
    if (cta) cta.lastChild.textContent = ` ${file.name}`
  }

  // Foto elegida de la galería: se descarta la que se iba a subir
  pick(event) {
    const src = event.target.dataset.src
    if (this.hasFileTarget) this.fileTarget.value = ""
    if (src) this.setPreview(src)
    const summary = this.element.querySelector(".gallery-pick summary")
    if (summary) summary.textContent = src ? `De la galería: ${event.target.closest("label").title}` : "…o elegí una de la galería"
  }

  setPreview(src) {
    this.previewTarget.src = src
    this.previewTarget.classList.remove("is-empty", "is-new")
    void this.previewTarget.offsetWidth
    this.previewTarget.classList.add("is-new")
  }
}
