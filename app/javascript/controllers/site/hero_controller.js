import { Controller } from "@hotwired/stimulus"

// Timecode a 24 fps y el texto del hero que se aleja al bajar.
export default class extends Controller {
  static targets = ["copy", "timecode"]

  connect() {
    this.reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    const start = performance.now()
    const pad = (n) => String(n).padStart(2, "0")
    if (this.reduce) {
      this.timecodeTarget.textContent = "00:00:00:06"
    } else {
      this.timer = setInterval(() => {
        const f = Math.floor((performance.now() - start) / (1000 / 24))
        this.timecodeTarget.textContent = [Math.floor(f / 86400), Math.floor(f / 1440) % 60, Math.floor(f / 24) % 60, f % 24].map(pad).join(":")
      }, 1000 / 24)
    }
    this.onScroll = () => {
      if (this.ticking || this.reduce) return
      this.ticking = true
      requestAnimationFrame(() => {
        this.ticking = false
        const p = Math.min(1, Math.max(0, window.scrollY / window.innerHeight))
        this.copyTarget.style.transform = `translateY(${p * 90}px) scale(${1 - p * 0.14})`
        this.copyTarget.style.opacity = String(1 - p * 1.25)
      })
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
  }

  disconnect() {
    clearInterval(this.timer)
    window.removeEventListener("scroll", this.onScroll)
  }
}
