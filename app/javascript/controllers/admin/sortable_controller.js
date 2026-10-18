import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Arrastrar para ordenar. Guarda el orden al soltar y marca la fila con un destello.
export default class extends Controller {
  static values = { model: String, url: String, handle: { type: String, default: ".sort-handle" } }

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: this.handleValue,
      animation: 180,
      easing: "cubic-bezier(.2,.8,.2,1)",
      ghostClass: "sort-ghost",
      chosenClass: "sort-chosen",
      onEnd: (event) => this.save(event)
    })
  }

  disconnect() { this.sortable?.destroy() }

  async save(event) {
    if (event.oldIndex === event.newIndex) return
    const ids = [...this.element.children].map((el) => el.dataset.id).filter(Boolean)
    // Si es un formulario anidado, actualizar los campos position
    this.element.querySelectorAll("[data-position-field]").forEach((input, i) => { input.value = i + 1 })
    if (!this.modelValue) return
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const res = await fetch(this.urlValue, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token, Accept: "application/json" },
      body: JSON.stringify({ model: this.modelValue, ids })
    })
    if (res.ok) {
      event.item.classList.remove("saved-flash"); void event.item.offsetWidth; event.item.classList.add("saved-flash")
    } else {
      alert("No se pudo guardar el orden. Revisá tu conexión e intentá de nuevo.")
    }
  }
}
