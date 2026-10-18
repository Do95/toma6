import { Controller } from "@hotwired/stimulus"

// Agregar y quitar filas (opciones de servicio, ítems de cotización).
// La plantilla usa NEW_RECORD como índice provisorio.
export default class extends Controller {
  static targets = ["template", "list"]
  static values = { removeField: { type: String, default: "_destroy" } }

  add(event) {
    event?.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, `${Date.now()}${Math.floor(Math.random() * 100)}`)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    const row = this.listTarget.lastElementChild
    row.querySelector("input:not([type=hidden]),textarea,select")?.focus()
    this.dispatch("changed")
  }

  remove(event) {
    event.preventDefault()
    const row = event.currentTarget.closest("[data-nested-row]")
    const finish = () => {
      if (row.dataset.newRecord === "true") row.remove()
      else {
        const flag = row.querySelector(`input[name$="[${this.removeFieldValue}]"]`)
        if (flag) flag.value = "1"
        row.hidden = true
      }
      this.dispatch("changed")
    }
    row.classList.add("is-removing")
    setTimeout(finish, 240)
  }
}
