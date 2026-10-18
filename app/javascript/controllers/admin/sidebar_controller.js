import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() { document.body.classList.toggle("sidebar-open") }
  close() { document.body.classList.remove("sidebar-open") }
  disconnect() { this.close() }
}
