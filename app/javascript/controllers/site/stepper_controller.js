import { Controller } from "@hotwired/stimulus"

// Botones − / + para las opciones por cantidad del cotizador.
export default class extends Controller {
  static targets = ["input"]
  static values = { min: Number, max: Number }

  up() { this.set(Number(this.inputTarget.value || 0) + 1) }
  down() { this.set(Number(this.inputTarget.value || 0) - 1) }

  set(value) {
    const v = Math.min(this.maxValue, Math.max(this.minValue, value))
    if (String(v) === this.inputTarget.value) {
      this.element.animate([{ transform: "translateX(0)" }, { transform: "translateX(-3px)" }, { transform: "translateX(3px)" }, { transform: "translateX(0)" }], { duration: 220 })
      return
    }
    this.inputTarget.value = v
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.inputTarget.animate([{ transform: "scale(1.25)" }, { transform: "scale(1)" }], { duration: 200, easing: "cubic-bezier(.2,.8,.2,1)" })
  }
}
