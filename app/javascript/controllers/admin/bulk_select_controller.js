import { Controller } from "@hotwired/stimulus"

// Selección múltiple en grillas de fotos. Con Shift se elige un rango.
export default class extends Controller {
  static targets = ["checkbox", "bar", "count", "ids", "targetField"]

  connect() {
    this.shift = false
    this.onKey = (e) => { this.shift = e.shiftKey }
    window.addEventListener("keydown", this.onKey)
    window.addEventListener("keyup", this.onKey)
  }

  disconnect() {
    window.removeEventListener("keydown", this.onKey)
    window.removeEventListener("keyup", this.onKey)
  }

  toggle(event) {
    const box = event.target
    const boxes = this.checkboxTargets
    const index = boxes.indexOf(box)
    if ((this.shift || event.shiftKey) && this.lastIndex !== undefined && this.lastIndex !== index) {
      const [a, b] = [this.lastIndex, index].sort((x, y) => x - y)
      boxes.slice(a, b + 1).forEach((c) => { c.checked = box.checked })
    }
    this.lastIndex = index
    this.update()
  }

  all() {
    const select = this.checkboxTargets.some((c) => !c.checked)
    this.checkboxTargets.forEach((c) => { c.checked = select })
    this.update()
  }

  clear() {
    this.checkboxTargets.forEach((c) => { c.checked = false })
    this.lastIndex = undefined
    this.update()
  }

  update() {
    this.checkboxTargets.forEach((c) => c.closest(".media-card")?.classList.toggle("is-selected", c.checked))
    const ids = this.checkboxTargets.filter((c) => c.checked).map((c) => c.value)
    this.countTarget.textContent = ids.length
    this.barTarget.classList.toggle("is-visible", ids.length > 0)
    this.element.classList.toggle("bulk-on", ids.length > 0)
    this.idsTarget.innerHTML = ids.map((id) => `<input type="hidden" name="ids[]" value="${id}">`).join("")
  }

  action(event) {
    const value = event.target.value
    this.targetFieldTargets.forEach((el) => { el.hidden = !el.dataset.for.split(",").includes(value) })
  }

  // Acciones destructivas: confirmación con el modal de la marca
  async confirm(event) {
    const form = event.target
    const action = form.querySelector("[name=bulk_action]")?.value
    if (!["trash", "purge"].includes(action) || form.dataset.confirmed === "1") return
    event.preventDefault()
    event.stopImmediatePropagation()
    const n = this.countTarget.textContent
    const { openConfirm } = await import("lib/confirm")
    const ok = await openConfirm(action === "purge"
      ? { title: "¿Eliminar definitivamente?", message: `Se borran ${n} medios para siempre, con sus archivos, de todas sus galerías. No se puede deshacer.`, button: "Eliminar para siempre" }
      : { title: "¿Enviar a la papelera?", message: `${n} medios van a la papelera y se quitan de todas sus galerías.`, button: "Enviar a la papelera" })
    if (!ok) return
    form.dataset.confirmed = "1"
    form.requestSubmit()
    setTimeout(() => { delete form.dataset.confirmed }, 1000)
  }
}
