import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { after: { type: Number, default: 5000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.afterValue)
  }

  disconnect() { clearTimeout(this.timer) }

  dismiss() {
    this.element.classList.add("is-leaving")
    setTimeout(() => this.element.remove(), 300)
  }
}
