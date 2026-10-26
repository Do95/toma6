import { Controller } from "@hotwired/stimulus"

// Editor de cotizaciones: calcula totales en vivo y completa precio y
// descripción al elegir un servicio del catálogo.
export default class extends Controller {
  static targets = ["subtotal", "discount", "tax", "total", "taxLabel", "taxRow"]
  static values = { currency: String, services: Object }

  connect() { this.recalc() }

  pickService(event) {
    const row = event.target.closest("[data-nested-row]")
    const svc = this.servicesValue[event.target.value]
    if (!row || !svc) return
    const desc = row.querySelector("[data-field=description]")
    const price = row.querySelector("[data-field=unit_price]")
    if (desc && !desc.value) desc.value = svc.title
    if (price && (!price.value || Number(price.value) === 0)) price.value = svc.price
    this.recalc()
  }

  recalc() {
    let subtotal = 0
    this.element.querySelectorAll("[data-nested-row]").forEach((row) => {
      if (row.hidden || row.classList.contains("is-removing")) return
      const q = Number(row.querySelector("[data-field=quantity]")?.value || 0)
      const p = Number(row.querySelector("[data-field=unit_price]")?.value || 0)
      const line = Math.round(q * p * 100) / 100
      subtotal += line
      const cell = row.querySelector("[data-line-total]")
      if (cell) cell.textContent = this.money(line)
    })
    const type = this.element.querySelector("[name='quote[discount_type]']")?.value
    const dval = Number(this.element.querySelector("[name='quote[discount_value]']")?.value || 0)
    const rate = Number(this.element.querySelector("[name='quote[tax_rate]']")?.value || 0)
    const discount = Math.min(subtotal, type === "percent" ? subtotal * dval / 100 : dval)
    const tax = (subtotal - discount) * rate / 100
    const total = subtotal - discount + tax
    this.set(this.subtotalTarget, subtotal)
    this.set(this.discountTarget, -discount)
    this.set(this.taxTarget, tax)
    this.set(this.totalTarget, total)
    if (this.hasTaxLabelTarget) this.taxLabelTarget.textContent = `${rate}%`
    if (this.hasTaxRowTarget) this.taxRowTarget.hidden = !(rate > 0) // sin impuesto, la fila no aparece
  }

  set(el, value) {
    const text = value < 0 ? `−${this.money(-value)}` : this.money(value)
    if (el.textContent === text) return
    el.textContent = text
    el.classList.remove("money-flash"); void el.offsetWidth; el.classList.add("money-flash")
  }

  money(v) {
    return `${this.currencyValue}${(Math.round(v * 100) / 100).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
  }
}
