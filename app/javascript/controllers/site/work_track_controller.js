import { Controller } from "@hotwired/stimulus"

// "Trabajos recientes": scroll vertical que mueve la fila de proyectos en horizontal.
// Los videos se cargan solo cuando aparecen en pantalla.
export default class extends Controller {
  static targets = ["track", "video"]

  connect() {
    this.size = () => {
      const extra = Math.max(0, this.trackTarget.scrollWidth - window.innerWidth)
      this.element.style.height = `${window.innerHeight + extra}px`
    }
    this.onScroll = () => requestAnimationFrame(() => this.update())
    this.onResize = () => { this.size(); this.update() }
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onResize)
    window.addEventListener("load", this.onResize)
    this.size(); this.update()

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.io = new IntersectionObserver((entries) => {
      entries.forEach(({ target, isIntersecting }) => {
        if (isIntersecting && !reduce) {
          if (!target.src) target.src = target.dataset.src
          target.play().catch(() => {})
        } else if (!target.paused) target.pause()
      })
    }, { threshold: 0.35 })
    this.videoTargets.forEach((v) => this.io.observe(v))
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onResize)
    window.removeEventListener("load", this.onResize)
    this.io?.disconnect()
  }

  update() {
    const r = this.element.getBoundingClientRect()
    const range = r.height - window.innerHeight
    const p = range > 0 ? Math.min(1, Math.max(0, -r.top / range)) : 0
    const maxX = Math.max(0, this.trackTarget.scrollWidth - window.innerWidth)
    this.trackTarget.style.transform = `translate3d(${(-p * maxX).toFixed(1)}px,0,0)`
  }
}
