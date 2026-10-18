import { Controller } from "@hotwired/stimulus"

// Envía el formulario de filtros al cambiar un campo (con pausa al escribir).
export default class extends Controller {
  submit() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), 300)
  }
}
