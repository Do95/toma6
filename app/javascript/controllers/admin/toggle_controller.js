import { Controller } from "@hotwired/stimulus"

// Muestra u oculta bloques según un select o checkbox.
//   data-toggle-target="item" data-show-when="choice,quantity"
export default class extends Controller {
  static targets = ["source", "item"]

  connect() { this.update() }

  update() {
    const src = this.sourceTarget
    const value = src.type === "checkbox" ? String(src.checked) : (src.type === "radio" ? this.element.querySelector(`[name="${src.name}"]:checked`)?.value : src.value)
    this.itemTargets.forEach((el) => {
      const show = el.dataset.showWhen.split(",").includes(value)
      if (show && el.hidden) { el.hidden = false; el.animate?.([{ opacity: 0, transform: "translateY(-4px)" }, { opacity: 1, transform: "none" }], { duration: 200 }) }
      else if (!show) el.hidden = true
    })
  }
}
