import { Controller } from "@hotwired/stimulus"

// Inserta variables ({{nombre}}) en el último campo que tuvo el foco.
export default class extends Controller {
  static targets = ["field"]

  remember(event) { this.last = event.target }

  insert(event) {
    const field = this.last || this.fieldTargets.at(-1)
    const token = event.currentTarget.dataset.token
    const start = field.selectionStart ?? field.value.length
    const end = field.selectionEnd ?? field.value.length
    field.value = field.value.slice(0, start) + token + field.value.slice(end)
    field.focus()
    field.setSelectionRange(start + token.length, start + token.length)
    event.currentTarget.animate([{ transform: "scale(.9)" }, { transform: "scale(1)" }], { duration: 160 })
  }
}
