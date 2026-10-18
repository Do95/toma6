import { Controller } from "@hotwired/stimulus"

// Muestra cómo queda el número de la próxima cotización mientras se configura.
export default class extends Controller {
  static targets = ["prefix", "digits", "start", "year", "sample"]

  update() {
    const prefix = (this.prefixTarget.value || "").trim().toUpperCase()
    const digits = Math.min(8, Math.max(3, Number(this.digitsTarget.value) || 4))
    const start = Math.max(1, Number(this.startTarget.value) || 1)
    // Se mantiene el correlativo actual si es mayor que "Empezar en"
    const current = Number((this.sampleTarget.dataset.next.match(/(\d+)$/) || [])[1] || 1)
    const seq = String(Math.max(start, current)).padStart(digits, "0")
    const parts = [prefix || null, this.yearTarget.checked ? this.sampleTarget.dataset.year : null, seq].filter(Boolean)
    this.sampleTarget.textContent = parts.join("-")
    this.sampleTarget.animate?.([{ transform: "scale(1.06)" }, { transform: "scale(1)" }], { duration: 160 })
  }
}
