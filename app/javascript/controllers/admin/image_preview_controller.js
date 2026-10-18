import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview"]

  show(event) {
    const file = event.target.files?.[0]
    if (!file || !file.type.startsWith("image/")) return
    const url = URL.createObjectURL(file)
    this.previewTarget.src = url
    this.previewTarget.classList.remove("is-empty", "is-new")
    void this.previewTarget.offsetWidth
    this.previewTarget.classList.add("is-new")
    const cta = this.element.querySelector(".dz-cta")
    if (cta) cta.lastChild.textContent = ` ${file.name}`
  }
}
