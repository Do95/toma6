import { Controller } from "@hotwired/stimulus"
import { shrinkImage } from "lib/media_upload"

export default class extends Controller {
  static targets = ["preview"]

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
    const url = URL.createObjectURL(file)
    this.previewTarget.src = url
    this.previewTarget.classList.remove("is-empty", "is-new")
    void this.previewTarget.offsetWidth
    this.previewTarget.classList.add("is-new")
    const cta = this.element.querySelector(".dz-cta")
    if (cta) cta.lastChild.textContent = ` ${file.name}`
  }
}
