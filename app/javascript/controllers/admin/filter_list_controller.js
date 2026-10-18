import { Controller } from "@hotwired/stimulus"

// Filtra una lista de casillas mientras escribís.
export default class extends Controller {
  static targets = ["item"]

  filter(event) {
    const q = event.target.value.trim().toLowerCase()
    this.itemTargets.forEach((el) => { el.hidden = q && !el.textContent.toLowerCase().includes(q) })
  }
}
