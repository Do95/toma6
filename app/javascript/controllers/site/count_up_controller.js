import { Controller } from "@hotwired/stimulus"

// Las cifras suben desde cero cuando aparecen en pantalla ("150+", "5 años", "$1,200").
export default class extends Controller {
  connect() {
    const text = this.element.textContent.trim()
    const m = text.match(/^(\D*)([\d.,]+)(.*)$/)
    if (!m || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    const [, pre, num, post] = m
    const target = Number(num.replace(/,/g, ""))
    if (!Number.isFinite(target) || target === 0) return
    const decimals = (num.split(".")[1] || "").length
    const fmt = (v) => `${pre}${v.toLocaleString("en-US", { minimumFractionDigits: decimals, maximumFractionDigits: decimals })}${post}`
    this.element.textContent = fmt(0)
    this.io = new IntersectionObserver(([entry]) => {
      if (!entry.isIntersecting) return
      this.io.disconnect()
      const t0 = performance.now()
      const tick = () => {
        const p = Math.min(1, (performance.now() - t0) / 1200)
        this.element.textContent = fmt(target * (1 - Math.pow(1 - p, 3)))
        if (p < 1) requestAnimationFrame(tick)
      }
      requestAnimationFrame(tick)
    }, { threshold: 0.6 })
    this.io.observe(this.element)
  }

  disconnect() { this.io?.disconnect() }
}
