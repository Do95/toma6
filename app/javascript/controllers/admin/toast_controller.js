import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const ms = this.element.classList.contains("toast-error") ? 9000 : 5000
    this.timer = setTimeout(() => this.dismiss(), ms)
    this.element.addEventListener("mouseenter", () => clearTimeout(this.timer))
    this.element.addEventListener("mouseleave", () => { this.timer = setTimeout(() => this.dismiss(), 2500) })
  }
  disconnect() { clearTimeout(this.timer) }
  dismiss() {
    this.element.classList.add("is-leaving")
    setTimeout(() => this.element.remove(), 300)
  }
}
