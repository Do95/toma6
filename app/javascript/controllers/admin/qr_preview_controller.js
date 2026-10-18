import { Controller } from "@hotwired/stimulus"

// Vista previa del QR mientras se edita el enlace.
export default class extends Controller {
  static targets = ["image", "code", "label"]
  static values = { url: String }

  connect() { this.refresh() }

  refresh() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.load(), 250)
  }

  load() {
    const style = this.element.querySelector("[name='short_link[qr_style]']:checked")?.value || "brand"
    const logo = this.element.querySelector("input[type=checkbox][name='short_link[qr_logo]']")
    const params = new URLSearchParams({
      code: this.codeTarget.value || "ejemplo",
      style,
      logo: logo && !logo.checked ? "0" : "1",
      label: this.labelTarget.value
    })
    const img = this.imageTarget
    img.style.opacity = ".4"
    img.onload = () => {
      img.style.opacity = "1"
      img.animate?.([{ transform: "scale(.97)" }, { transform: "scale(1)" }], { duration: 180 })
    }
    img.src = `${this.urlValue}?${params}`
  }

  // El interruptor del logo es un checkbox dentro de switch_field
  disconnect() { clearTimeout(this.timer) }
}
