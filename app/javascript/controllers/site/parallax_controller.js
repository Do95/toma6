import { Controller } from "@hotwired/stimulus"

// Parallax por capas: cada elemento con data-speed se desplaza según su sección.
export default class extends Controller {
  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    this.layers = [...this.element.querySelectorAll("[data-speed]")]
    this.onScroll = () => {
      if (this.ticking) return
      this.ticking = true
      requestAnimationFrame(() => this.update())
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onScroll)
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onScroll)
  }

  update() {
    this.ticking = false
    const vh = window.innerHeight
    for (const el of this.layers) {
      const root = el.closest(".pr") || el.parentElement
      const r = root.getBoundingClientRect()
      if (r.bottom < -200 || r.top > vh + 200) continue
      const d = (r.top + r.height / 2) - vh / 2
      el.style.transform = `translate3d(0,${(-d * parseFloat(el.dataset.speed)).toFixed(1)}px,0)`
    }
  }
}
