import { Controller } from "@hotwired/stimulus"

// Visor de fotos y videos. La imagen "vuela" desde el mosaico hasta el visor
// (y vuelve al cerrar). Teclado: ← → Esc. En móvil: deslizar.
export default class extends Controller {
  static targets = ["overlay", "stage", "caption", "counter", "item", "strip"]

  connect() {
    this.onKey = (e) => {
      if (this.overlayTarget.hidden) return
      if (e.key === "Escape") this.close()
      if (e.key === "ArrowRight") this.next()
      if (e.key === "ArrowLeft") this.prev()
      if (e.key === "Tab") this.trapFocus(e)
    }
    document.addEventListener("keydown", this.onKey)
    // Al cambiar el tamaño de la ventana (o girar el celular) se reajusta el visor
    this.onResize = () => { if (!this.overlayTarget.hidden && this.items) this.fit() }
    window.addEventListener("resize", this.onResize)
    // Turbo guarda una copia de la página al salir: que no quede el visor abierto
    this.onBeforeCache = () => this.close({ instant: true })
    document.addEventListener("turbo:before-cache", this.onBeforeCache)
    this.overlayTarget.addEventListener("click", (e) => { if (e.target === this.overlayTarget) this.close() })
    // Deslizar cambia de foto, salvo en la tira de miniaturas (se desplaza) o sobre un video (controles)
    this.overlayTarget.addEventListener("touchstart", (e) => {
      this.touchX = e.target.closest(".lb-strip, video") ? null : e.touches[0].clientX
    }, { passive: true })
    this.overlayTarget.addEventListener("touchend", (e) => {
      if (this.touchX == null) return
      const dx = e.changedTouches[0].clientX - this.touchX
      if (Math.abs(dx) > 50) dx < 0 ? this.next() : this.prev()
    })
    // Enlace directo: /galeria#foto-12 abre esa foto
    const m = window.location.hash.match(/^#foto-(\d+)$/)
    if (m) setTimeout(() => {
      const tile = this.itemTargets.find((t) => t.id === `foto-${m[1]}`)
      if (tile) { tile.scrollIntoView({ block: "center" }); this.open({ currentTarget: tile }) }
    }, 250)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKey)
    window.removeEventListener("resize", this.onResize)
    document.removeEventListener("turbo:before-cache", this.onBeforeCache)
    document.documentElement.style.overflow = ""
  }

  get visibleItems() {
    return this.itemTargets.filter((el) => !el.hidden && !el.closest("[hidden]"))
  }

  open(event) {
    const tile = event.currentTarget
    this.items = this.visibleItems
    this.index = Math.max(0, this.items.indexOf(tile))
    this.lastFocus = tile
    this.overlayTarget.hidden = false
    this.overlayTarget.classList.add("open")
    document.documentElement.style.overflow = "hidden"
    this.render({ from: tile })
    this.buildStrip()
    this.overlayTarget.querySelector(".lb-close").focus({ preventScroll: true })
  }

  close({ instant = false } = {}) {
    if (this.overlayTarget.hidden) return
    const tile = this.items?.[this.index]
    const media = this.stageTarget.firstElementChild
    media?.pause?.()
    const finish = () => {
      // La animación de cierre queda "congelada" (fill: forwards); si no se cancela,
      // la próxima vez que se abre el visor la foto aparece corrida y achicada.
      this.stageTarget.getAnimations().forEach((a) => a.cancel())
      this.overlayTarget.hidden = true
      this.overlayTarget.classList.remove("open")
      this.stageTarget.innerHTML = ""
      document.documentElement.style.overflow = ""
      if (window.location.hash.startsWith("#foto-")) history.replaceState(history.state, "", window.location.pathname + window.location.search)
      this.lastFocus?.focus({ preventScroll: true })
    }
    if (!instant && tile && !this.reduced && this.onScreen(tile)) {
      const anim = this.flip(this.stageTarget, tile.getBoundingClientRect(), true)
      this.overlayTarget.animate([{ backgroundColor: "rgba(8,6,6,.95)" }, { backgroundColor: "rgba(8,6,6,0)" }], { duration: 260 })
      anim.onfinish = finish
    } else if (!instant && !this.reduced) {
      // La foto quedó fuera de la pantalla: se desvanece en lugar de volar hacia ella
      this.overlayTarget.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 200 }).onfinish = finish
    } else finish()
  }

  onScreen(el) {
    const r = el.getBoundingClientRect()
    return r.width > 0 && r.bottom > 0 && r.top < window.innerHeight && r.right > 0 && r.left < window.innerWidth
  }

  // Mantiene el foco dentro del visor mientras está abierto
  trapFocus(e) {
    const focusable = [...this.overlayTarget.querySelectorAll("button, a[href], video[controls]")].filter((el) => !el.closest("[hidden]"))
    if (!focusable.length) return
    const first = focusable[0], last = focusable[focusable.length - 1]
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus() }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus() }
    else if (!this.overlayTarget.contains(document.activeElement)) { e.preventDefault(); first.focus() }
  }

  next() { this.step(1) }
  prev() { this.step(-1) }

  step(dir) {
    if (!this.items?.length) return
    this.stageTarget.firstElementChild?.pause?.()
    this.index = (this.index + dir + this.items.length) % this.items.length
    this.render({ dir })
  }

  render({ from = null, dir = 0 } = {}) {
    const data = JSON.parse(this.items[this.index].dataset.lb)
    this.fit(data)

    let media
    if (data.type === "video") {
      media = document.createElement("video")
      Object.assign(media, { src: data.src, poster: data.poster || "", controls: true, autoplay: true, playsInline: true })
    } else {
      media = document.createElement("img")
      media.src = data.src
      media.alt = data.title || ""
    }
    this.stageTarget.replaceChildren(media)

    const parts = [`<strong>${this.escape(data.title || "")}</strong>`]
    if (data.desc) parts.push(`<span class="lb-desc">${this.escape(data.desc)}</span>`)
    const also = (data.also || []).filter((g) => g.url !== window.location.pathname)
    if (also.length) {
      parts.push(`<span class="lb-also">Aparece en: ${also.map((g) => `<a href="${this.escape(g.url)}#foto-${data.id}">${this.escape(g.label)}</a>`).join(" · ")}</span>`)
    }
    this.captionTarget.innerHTML = parts.join("")
    this.counterTarget.textContent = `${this.index + 1} / ${this.items.length}`
    if (data.id) history.replaceState(history.state, "", `${window.location.pathname}${window.location.search}#foto-${data.id}`)
    this.highlightStrip()
    this.preloadNeighbors()

    if (this.reduced) return
    if (from) this.flip(this.stageTarget, from.getBoundingClientRect(), false)
    else if (dir) this.stageTarget.animate(
      [{ opacity: 0, transform: `translateX(${dir * 40}px)` }, { opacity: 1, transform: "none" }],
      { duration: 260, easing: "cubic-bezier(.2,.8,.2,1)" }
    )
  }

  // Ajusta el tamaño del visor a la proporción de la foto y al espacio disponible
  fit(data = JSON.parse(this.items[this.index].dataset.lb)) {
    const [rw, rh] = String(data.ratio || "4/5").split("/").map(Number)
    const ratio = rw > 0 && rh > 0 ? rw / rh : 4 / 5
    const maxW = Math.min(window.innerWidth - (window.innerWidth < 760 ? 32 : 168), 1400)
    const maxH = Math.max(160, window.innerHeight - (window.innerWidth < 760 ? 280 : 270))
    let w = maxW, h = w / ratio
    if (h > maxH) { h = maxH; w = h * ratio }
    this.stageTarget.style.width = `${Math.round(w)}px`
    this.stageTarget.style.height = `${Math.round(h)}px`
  }

  // Tira de miniaturas para saltar a cualquier foto
  buildStrip() {
    if (!this.hasStripTarget) return
    this.stripTarget.hidden = this.items.length < 2
    this.stripTarget.innerHTML = this.items.map((tile, i) => {
      const d = JSON.parse(tile.dataset.lb)
      return `<button type="button" data-i="${i}" aria-label="Ver ${this.escape(d.title || "foto " + (i + 1))}"><img src="${this.escape(d.thumb || d.poster || d.src)}" alt="" loading="lazy"></button>`
    }).join("")
    this.stripTarget.querySelectorAll("button").forEach((b) => b.addEventListener("click", (e) => {
      e.stopPropagation()
      const i = Number(b.dataset.i)
      if (i === this.index) return
      const dir = i > this.index ? 1 : -1
      this.stageTarget.firstElementChild?.pause?.()
      this.index = i
      this.render({ dir })
    }))
    this.highlightStrip()
  }

  highlightStrip() {
    if (!this.hasStripTarget) return
    this.stripTarget.querySelectorAll("button").forEach((b, i) => {
      const on = i === this.index
      b.classList.toggle("is-on", on)
      if (on) b.scrollIntoView?.({ inline: "center", block: "nearest", behavior: this.reduced ? "auto" : "smooth" })
    })
  }

  // La foto siguiente y la anterior ya quedan cargadas
  preloadNeighbors() {
    ;[1, -1].forEach((d) => {
      const tile = this.items[(this.index + d + this.items.length) % this.items.length]
      if (!tile) return
      const data = JSON.parse(tile.dataset.lb)
      if (data.type !== "video") { const img = new Image(); img.src = data.src }
    })
  }

  // FLIP: anima el visor entre su posición final y el rectángulo del mosaico.
  flip(el, rect, reverse) {
    const end = el.getBoundingClientRect()
    const dx = rect.left + rect.width / 2 - (end.left + end.width / 2)
    const dy = rect.top + rect.height / 2 - (end.top + end.height / 2)
    const s = rect.width / end.width
    const frames = [
      { transform: `translate(${dx}px, ${dy}px) scale(${s})`, borderRadius: "14px" },
      { transform: "none", borderRadius: "12px" }
    ]
    return el.animate(reverse ? frames.reverse() : frames, { duration: reverse ? 260 : 380, easing: "cubic-bezier(.2,.8,.2,1)", fill: reverse ? "forwards" : "none" })
  }

  get reduced() { return window.matchMedia("(prefers-reduced-motion: reduce)").matches }

  escape(s) { return String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]) }

  // Vista previa muda de los videos al pasar el mouse por el mosaico.
  itemTargetConnected(tile) {
    if (!tile.dataset.preview) return
    if (!window.matchMedia("(hover: hover) and (pointer: fine)").matches || this.reduced) return
    let v = null
    tile.addEventListener("mouseenter", () => {
      if (!v) {
        v = Object.assign(document.createElement("video"), { muted: true, loop: true, playsInline: true, preload: "auto", src: tile.dataset.preview, className: "tile-video" })
        v.addEventListener("playing", () => { v.style.opacity = "1" })
        tile.insertBefore(v, tile.querySelector(".vid-badge"))
      }
      v.play().catch(() => {})
    })
    tile.addEventListener("mouseleave", () => { if (v) { v.pause(); v.style.opacity = "0" } })
  }
}
