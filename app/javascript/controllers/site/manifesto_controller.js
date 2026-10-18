import { Controller } from "@hotwired/stimulus"

// Revela el manifiesto palabra por palabra mientras se hace scroll.
export default class extends Controller {
  static targets = ["text"]

  connect() {
    const words = this.textTarget.textContent.trim().split(/\s+/)
    this.textTarget.innerHTML = words.map((w) => `<span class="w">${w.replace(/</g, "&lt;")}</span>`).join(" ")
    this.words = this.textTarget.querySelectorAll(".w")
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.words.forEach((w) => w.classList.add("on"))
      return
    }
    this.onScroll = () => requestAnimationFrame(() => this.update())
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.update()
  }

  disconnect() { window.removeEventListener("scroll", this.onScroll) }

  update() {
    const r = this.element.getBoundingClientRect()
    const p = Math.min(1, Math.max(0, -r.top / (r.height - window.innerHeight)))
    const lit = Math.round(p * 1.15 * this.words.length)
    this.words.forEach((w, i) => w.classList.toggle("on", i < lit))
  }
}
