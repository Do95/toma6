import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    await navigator.clipboard.writeText(this.sourceTarget.value)
    const label = this.buttonTarget.innerHTML
    this.buttonTarget.textContent = "¡Copiado!"
    setTimeout(() => { this.buttonTarget.innerHTML = label }, 1600)
  }
}
