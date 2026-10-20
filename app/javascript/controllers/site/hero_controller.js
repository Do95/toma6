import { Controller } from "@hotwired/stimulus"

// Hero con lente de cine. Al entrar: el diafragma se abre (f/22 → f/2.8), el anillo de foco
// gira de ∞ a 2 m y el texto pasa de desenfocado a nítido; el cuadro de AF «busca» y traba.
// Al bajar, el diafragma se cierra y el texto se desenfoca mientras se aleja.
// Misma geometría que IrisHelper (app/helpers/iris_helper.rb).
const IRIS = { blades: 9, open: 160, closed: 12, len: 520 }
const F_STOPS = ["1.4", "2", "2.8", "4", "5.6", "8", "11", "16", "22"]
const MAX_BLUR = 14

const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v))
const easeOutQuart = (t) => 1 - Math.pow(1 - t, 4)
const easeInOut = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2)
const span = (t, from, to) => clamp((t - from) / (to - from))

export default class extends Controller {
  static targets = ["copy", "timecode", "fRing", "focusRing", "dof", "fstop", "af", "afLabel"]

  connect() {
    this.reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.leaves = [...this.element.querySelectorAll(".iris-leaf")]
    this.edges = [...this.element.querySelectorAll(".iris-edge")]
    this.aperturePoly = this.element.querySelector(".iris-aperture")
    this.state = { aperture: 1, focus: 1, scroll: 0 }
    this.startTimecode()
    this.placeAf()
    this.onResize = () => this.placeAf()
    window.addEventListener("resize", this.onResize)

    if (this.reduce) {
      this.element.classList.add("is-live")
      this.render()
    } else {
      this.playIntro()
      this.onScroll = () => {
        if (this.ticking) return
        this.ticking = true
        requestAnimationFrame(() => {
          this.ticking = false
          this.state.scroll = clamp(window.scrollY / window.innerHeight)
          if (!this.intro) this.render()
        })
      }
      window.addEventListener("scroll", this.onScroll, { passive: true })
    }
  }

  disconnect() {
    clearInterval(this.timer)
    cancelAnimationFrame(this.raf)
    clearTimeout(this.afTimer)
    if (this.onScroll) window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onResize)
  }

  // El cuadro de AF vive fuera del texto (para no desenfocarse con él): se ubica sobre el
  // contenido, con un margen, sin pasarse de los bordes de la pantalla.
  placeAf() {
    const copy = this.copyTarget
    const cs = getComputedStyle(copy)
    const small = window.innerWidth < 700
    const gapX = small ? 10 : 40, gapY = small ? 14 : 26, edge = small ? 8 : 16
    const left = Math.max(edge, copy.offsetLeft + parseFloat(cs.paddingLeft) - gapX)
    const right = Math.min(this.element.clientWidth - edge, copy.offsetLeft + copy.offsetWidth - parseFloat(cs.paddingRight) + gapX)
    Object.assign(this.afTarget.style, {
      left: `${left}px`, width: `${right - left}px`,
      top: `${copy.offsetTop - gapY}px`, height: `${copy.offsetHeight + gapY * 2}px`
    })
  }

  // Timecode a 24 fps, como el monitor de la cámara
  startTimecode() {
    const pad = (n) => String(n).padStart(2, "0")
    if (this.reduce) { this.timecodeTarget.textContent = "00:00:00:06"; return }
    const start = performance.now()
    this.timer = setInterval(() => {
      const f = Math.floor((performance.now() - start) / (1000 / 24))
      this.timecodeTarget.textContent = [Math.floor(f / 86400), Math.floor(f / 1440) % 60, Math.floor(f / 24) % 60, f % 24].map(pad).join(":")
    }, 1000 / 24)
  }

  // Secuencia de entrada. En la misma sesión, la segunda vez es más corta.
  playIntro() {
    let seen = false
    try { seen = sessionStorage.getItem("toma6-hero") === "1"; sessionStorage.setItem("toma6-hero", "1") } catch (_) {}
    const k = seen ? 0.45 : 1
    const total = 2700 * k
    this.intro = true
    this.element.classList.add("is-intro", "is-live")
    this.afTarget.classList.add("is-hunting")
    this.afLabelTarget.classList.remove("is-locked")
    const t0 = performance.now()
    const tick = (now) => {
      const t = (now - t0) / k
      // 1. El diafragma abre de casi cerrado a f/2.8
      this.state.aperture = easeOutQuart(span(t, 150, 1750))
      // 2. Foco de ∞ a 2 m, pasándose un poco y volviendo (como un AF que busca)
      const f = easeInOut(span(t, 550, 1450))
      const hunt = Math.sin(span(t, 1250, 1900) * Math.PI) * 0.16
      this.state.focus = clamp(f + hunt, 0, 1.2)
      this.copyOpacity = span(t, 100, 700)
      this.render()
      if (t >= 1900 && !this.locked) this.lockFocus()
      if (now - t0 < total) {
        this.raf = requestAnimationFrame(tick)
      } else {
        this.intro = false
        this.copyOpacity = 1
        this.element.classList.remove("is-intro")
        this.render()
      }
    }
    this.raf = requestAnimationFrame(tick)
  }

  lockFocus() {
    this.locked = true
    this.afTarget.classList.remove("is-hunting")
    this.afTarget.classList.add("is-locked")
    this.afLabelTarget.classList.add("is-locked")
    this.afTimer = setTimeout(() => this.afTarget.classList.add("is-done"), 1100)
  }

  render() {
    const p = this.state.scroll
    // Al bajar: cierra el diafragma y desenfoca
    const aperture = clamp(this.state.aperture * (1 - p * 0.72))
    const focus = this.state.focus - p * 0.9
    this.drawIris(aperture)
    this.drawRings(aperture, clamp(focus, 0, 1.2))

    const blur = Math.min(MAX_BLUR, Math.abs(1 - focus) * MAX_BLUR)
    const copy = this.copyTarget.style
    copy.filter = blur > 0.15 ? `blur(${blur.toFixed(2)}px)` : ""
    copy.transform = `translateY(${p * 90}px) scale(${(1 - p * 0.14) * (1 + Math.max(0, 1 - focus) * 0.025)})`
    copy.opacity = String(Math.max(0, (this.copyOpacity ?? 1) - p * 1.25))
    this.afTarget.style.opacity = p > 0.02 ? "0" : ""
  }

  drawIris(aperture) {
    const n = IRIS.blades
    const r = IRIS.closed + (IRIS.open - IRIS.closed) * aperture
    const twist = -0.25 + (1 - aperture) * 0.55
    const half = r * Math.tan(Math.PI / n)
    const L = IRIS.len
    const f = (x, y) => `${x.toFixed(1)} ${y.toFixed(1)}`
    const verts = []
    for (let k = 0; k < n; k++) {
      const a = twist + (k * 2 * Math.PI) / n
      const nx = Math.cos(a), ny = Math.sin(a), dx = -ny, dy = nx
      const sx = 300 + nx * r - dx * half, sy = 300 + ny * r - dy * half
      const p2x = sx + dx * L, p2y = sy + dy * L
      const ex = sx + nx * L + dx * L * 0.3, ey = sy + ny * L + dy * L * 0.3
      const cx = sx + nx * L * 0.4 + dx * L * 0.14, cy = sy + ny * L * 0.4 + dy * L * 0.14
      this.leaves[k]?.setAttribute("d", `M${f(sx, sy)}L${f(p2x, p2y)}L${f(p2x + nx * L, p2y + ny * L)}L${f(ex, ey)}Q${f(cx, cy)} ${f(sx, sy)}Z`)
      this.edges[k]?.setAttribute("d", `M${f(sx, sy)}Q${f(cx, cy)} ${f(ex, ey)}`)
      verts.push(`${sx.toFixed(1)},${sy.toFixed(1)}`)
    }
    this.aperturePoly?.setAttribute("points", verts.join(" "))
  }

  drawRings(aperture, focus) {
    // Número f: de f/22 (cerrado) a f/2.8 (abierto); el anillo gira para dejarlo en la marca
    const stop = 8 - aperture * 6
    if (this.hasFRingTarget) this.fRingTarget.style.transform = `rotate(${(-(stop - 4) * 15).toFixed(2)}deg)`
    if (this.hasFstopTarget) this.fstopTarget.textContent = F_STOPS[Math.round(stop)]
    // Anillo de foco: ∞ en la marca cuando está desenfocado, 2 m al trabar
    if (this.hasFocusRingTarget) this.focusRingTarget.style.transform = `rotate(${((1 - Math.min(focus, 1.2)) * 66).toFixed(2)}deg)`
    // Profundidad de campo: más ancha cuanto más cerrado
    if (this.hasDofTarget) {
      const half = 6 + (1 - aperture) * 26, R = 246
      const pt = (deg) => { const a = ((deg - 90) * Math.PI) / 180; return `${(300 + R * Math.cos(a)).toFixed(1)} ${(300 + R * Math.sin(a)).toFixed(1)}` }
      this.dofTarget.setAttribute("d", `M${pt(-half)} A${R} ${R} 0 0 1 ${pt(half)}`)
    }
  }
}
