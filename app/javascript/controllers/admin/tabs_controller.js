import { Controller } from "@hotwired/stimulus"

// Pestañas con indicador que se desliza. Recuerda la pestaña en la URL (?tab=).
export default class extends Controller {
  static targets = ["tab", "panel", "ink", "field"]
  static values = { active: String }

  connect() {
    const initial = this.activeValue || this.tabTargets[0]?.dataset.tab
    this.show(initial, false)
    this.onResize = () => this.moveInk(false)
    window.addEventListener("resize", this.onResize)
  }

  disconnect() { window.removeEventListener("resize", this.onResize) }

  select(event) {
    event.preventDefault()
    this.show(event.currentTarget.dataset.tab, true)
  }

  show(name, animate) {
    this.current = name
    this.tabTargets.forEach((t) => t.setAttribute("aria-selected", String(t.dataset.tab === name)))
    this.panelTargets.forEach((p) => { p.hidden = p.dataset.tab !== name })
    if (this.hasFieldTarget) this.fieldTarget.value = name
    if (animate) {
      const url = new URL(window.location)
      url.searchParams.set("tab", name)
      history.replaceState(history.state, "", url)
    }
    this.moveInk(animate)
  }

  moveInk(animate) {
    const tab = this.tabTargets.find((t) => t.dataset.tab === this.current)
    if (!tab || !this.hasInkTarget) return
    if (!animate) this.inkTarget.style.transition = "none"
    this.inkTarget.style.left = `${tab.offsetLeft}px`
    this.inkTarget.style.width = `${tab.offsetWidth}px`
    if (!animate) requestAnimationFrame(() => { this.inkTarget.style.transition = "" })
  }
}
