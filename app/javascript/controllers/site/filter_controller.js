import { Controller } from "@hotwired/stimulus"

// Filtros de galería/proyectos con transición: lo que sale se achica y
// desvanece; lo que entra aparece en cascada.
export default class extends Controller {
  static targets = ["item", "count", "empty", "note"]
  static values = { emptyText: String }

  connect() {
    this.state = {}
  }

  pick(event) {
    const { key, value } = event.params
    const btn = event.currentTarget
    this.element.querySelectorAll(`[data-filter-key-param="${key}"]`).forEach((b) => {
      if (b.tagName === "BUTTON") b.setAttribute("aria-pressed", String(b === btn))
    })
    btn.animate([{ transform: "scale(.92)" }, { transform: "scale(1)" }], { duration: 180, easing: "ease-out" })
    this.state[key] = String(value ?? "")
    this.apply()
  }

  select(event) {
    this.state[event.params.key] = event.currentTarget.value
    this.apply()
  }

  reset() {
    this.state = {}
    this.element.querySelectorAll("[aria-pressed]").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.filterValueParam === "")))
    this.element.querySelectorAll("select").forEach((s) => { s.value = "" })
    this.apply()
  }

  matches(el) {
    return Object.entries(this.state).every(([key, value]) => {
      if (!value) return true
      if (!(key in el.dataset)) return true
      // Los valores pueden ser listas ("boda fiesta"): una foto puede estar en varias galerías
      return ` ${el.dataset[key]} `.includes(` ${value} `)
    })
  }

  apply() {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    let shown = 0
    let delay = 0
    this.itemTargets.forEach((el) => {
      const ok = this.matches(el)
      const counts = !el.classList.contains("album-card")
      if (ok && counts) shown++
      if (ok && el.hidden) {
        el.hidden = false
        if (!reduce) el.animate([{ opacity: 0, transform: "translateY(14px) scale(.96)" }, { opacity: 1, transform: "none" }],
          { duration: 320, delay: Math.min(delay += 30, 360), easing: "cubic-bezier(.2,.8,.2,1)", fill: "backwards" })
      } else if (!ok && !el.hidden) {
        if (reduce) { el.hidden = true; return }
        el.animate([{ opacity: 1, transform: "none" }, { opacity: 0, transform: "scale(.94)" }], { duration: 160, easing: "ease-in" })
          .onfinish = () => { if (!this.matches(el)) el.hidden = true }
      }
    })

    if (this.hasCountTarget) this.animateCount(this.countTarget, shown)
    if (this.hasEmptyTarget) {
      this.emptyTarget.hidden = shown > 0
      this.emptyTarget.innerHTML = `${this.emptyTextValue} <button type="button" data-action="filter#reset">Ver todo</button>`
    }
    this.noteTargets.forEach((n) => { n.hidden = n.dataset.album !== this.state.album })
  }

  animateCount(el, to) {
    const from = Number(el.textContent) || 0
    if (from === to) return
    const t0 = performance.now()
    const tick = () => {
      const p = Math.min(1, Math.max(0, (performance.now() - t0) / 300))
      el.textContent = Math.round(from + (to - from) * p)
      if (p < 1) requestAnimationFrame(tick)
    }
    requestAnimationFrame(tick)
  }
}
