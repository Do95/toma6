import { Controller } from "@hotwired/stimulus"

// Cotizador: suma en vivo lo que la persona elige. El servidor vuelve a calcular
// todo al enviar, así que estos números son solo para mostrar.
export default class extends Controller {
  static targets = ["service", "lines", "subtotal", "discount", "discountRow", "tax", "taxRow", "total",
                    "payload", "submit", "bar", "barTotal", "summary"]
  static values = { config: Object }

  connect() {
    this.services = new Map(this.configValue.services.map((s) => [String(s.id), s]))
    this.shown = 0
    // Si se volvió con errores, restaurar selección previa
    try {
      const prev = JSON.parse(this.payloadTarget.value || "[]")
      prev.forEach((sel) => {
        const card = this.serviceTargets.find((c) => c.dataset.serviceId === String(sel.service_id))
        if (!card) return
        card.querySelector(".est-service-head input").checked = true
        this.openCard(card, false)
        Object.entries(sel.options || {}).forEach(([id, qty]) => {
          const input = card.querySelector(`[data-option-id="${id}"]`)
          if (!input) return
          if (input.type === "number") input.value = qty
          else input.checked = true
        })
      })
    } catch (_) {}
    this.recalc()
  }

  toggleService(event) {
    const card = event.currentTarget.closest("[data-estimator-target='service']")
    if (event.currentTarget.checked) this.openCard(card, true)
    else this.closeCard(card)
    this.recalc()
  }

  openCard(card, animate) {
    card.classList.add("is-on")
    const opts = card.querySelector(".est-options")
    if (!opts) return
    opts.hidden = false
    if (animate && !this.reduced) {
      const h = opts.scrollHeight
      opts.animate([{ height: "0px", opacity: 0 }, { height: `${h}px`, opacity: 1 }], { duration: 280, easing: "cubic-bezier(.2,.8,.2,1)" })
    }
  }

  closeCard(card) {
    card.classList.remove("is-on")
    const opts = card.querySelector(".est-options")
    if (!opts) return
    if (this.reduced) { opts.hidden = true; return }
    opts.animate([{ height: `${opts.scrollHeight}px`, opacity: 1 }, { height: "0px", opacity: 0 }], { duration: 200, easing: "ease-in" })
      .onfinish = () => { if (!card.classList.contains("is-on")) opts.hidden = true }
  }

  recalc() {
    const lines = []
    const selections = []
    this.serviceTargets.forEach((card) => {
      if (!card.classList.contains("is-on")) return
      const svc = this.services.get(card.dataset.serviceId)
      if (!svc) return
      const options = {}
      lines.push({ label: svc.title, total: svc.base_price, head: true })
      svc.options.forEach((opt) => {
        const input = card.querySelector(`[data-option-id="${opt.id}"]`)
        if (!input) return
        let qty = 0
        if (opt.kind === "quantity") qty = Math.min(opt.max, Math.max(opt.min, Number(input.value) || 0))
        else qty = input.checked ? 1 : 0
        if (qty <= 0) return
        options[opt.id] = qty
        const label = opt.kind === "choice" ? `${opt.group}: ${opt.name}` : opt.name
        lines.push({ label: qty > 1 ? `${label} × ${qty}` : label, total: opt.price * qty })
      })
      selections.push({ service_id: svc.id, options })
    })

    const cfg = this.configValue
    const subtotal = lines.reduce((a, l) => a + l.total, 0)
    const discount = cfg.bundlePercent > 0 && selections.length >= cfg.bundleMin ? subtotal * cfg.bundlePercent / 100 : 0
    const tax = cfg.showTax ? (subtotal - discount) * cfg.taxRate / 100 : 0
    const total = subtotal - discount + tax

    this.renderLines(lines)
    this.subtotalTarget.textContent = this.money(subtotal)
    this.discountRowTarget.hidden = discount <= 0
    this.discountTarget.textContent = `−${this.money(discount)}`
    if (this.hasTaxRowTarget) { this.taxRowTarget.hidden = !cfg.showTax; this.taxTarget.textContent = this.money(tax) }
    if (discount > 0 && !this.hadDiscount && !this.reduced) {
      this.discountRowTarget.animate([{ transform: "scale(1.06)", background: "rgba(182,56,48,.25)" }, { transform: "none", background: "transparent" }], { duration: 600 })
    }
    this.hadDiscount = discount > 0
    this.countTo(total)
    this.payloadTarget.value = JSON.stringify(selections)
    this.submitTarget.disabled = selections.length === 0
    this.barTarget.classList.toggle("is-visible", selections.length > 0)
  }

  renderLines(lines) {
    if (!lines.length) {
      this.linesTarget.innerHTML = `<li class="est-empty">Elegí al menos un servicio para ver el precio.</li>`
      return
    }
    this.linesTarget.innerHTML = lines.map((l) =>
      `<li class="${l.head ? "is-head" : ""}"><span>${this.escape(l.label)}</span><span>${l.total > 0 ? this.money(l.total) : "Incluido"}</span></li>`
    ).join("")
  }

  // El total "rueda" hasta el nuevo valor, como un contador.
  countTo(to) {
    const els = [this.totalTarget, this.barTotalTarget]
    const from = this.shown
    this.shown = to
    if (this.reduced || from === to) { els.forEach((e) => { e.textContent = this.money(to) }); return }
    cancelAnimationFrame(this.raf)
    const t0 = performance.now()
    const dur = 450
    const tick = () => {
      const p = Math.min(1, Math.max(0, (performance.now() - t0) / dur))
      const eased = 1 - Math.pow(1 - p, 3)
      els.forEach((e) => { e.textContent = this.money(from + (to - from) * eased) })
      if (p < 1) this.raf = requestAnimationFrame(tick)
    }
    this.raf = requestAnimationFrame(tick)
    this.totalTarget.parentElement.animate([{ transform: "scale(1.03)" }, { transform: "scale(1)" }], { duration: 300 })
  }

  jumpToSummary(event) {
    event.preventDefault()
    this.summaryTarget.scrollIntoView({ behavior: this.reduced ? "auto" : "smooth", block: "start" })
  }

  beforeSubmit(event) {
    this.recalc()
    if (this.payloadTarget.value === "[]") {
      event.preventDefault()
      this.serviceTargets[0]?.animate([{ transform: "translateX(0)" }, { transform: "translateX(-6px)" }, { transform: "translateX(6px)" }, { transform: "translateX(0)" }], { duration: 300 })
      return
    }
    this.submitTarget.classList.add("is-sending")
    this.submitTarget.textContent = "Enviando…"
  }

  money(v) {
    const n = Math.round(v * 100) / 100
    const fixed = Number.isInteger(n) ? n.toLocaleString("en-US") : n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    return `${this.configValue.currency}${fixed}`
  }

  escape(s) { return String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]) }

  get reduced() { return window.matchMedia("(prefers-reduced-motion: reduce)").matches }
}
