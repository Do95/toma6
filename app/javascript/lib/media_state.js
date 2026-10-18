// Skeleton mientras cargan fotos, QR, PDF y vistas previas, e ilustración de la
// marca si una imagen no carga.
const BOXES = ".ph-tile, .project-card-media, .album-fan, .sx-split-media, .sx-col-media, .sx-full, .thumb, .link-qr, .pp-img, .project-hero-media, .monitor, .print > div, .phone > div, .qr-preview-card .card-body, .qr-card .card-body"
const SELF = "img.sort-thumb, img.qr-big, img.aside-preview, img.pj-img, iframe.pdf-frame, iframe.mail-frame, .lb-img img"

function boxFor(el) {
  if (el.matches(SELF)) return el
  return el.closest(BOXES)
}

function loaded(el) {
  if (el.tagName === "IFRAME") return false
  return el.complete && el.naturalWidth > 0
}

function track(el) {
  if (el.dataset.mediaTracked) return
  const box = boxFor(el)
  if (!box) return
  el.dataset.mediaTracked = "1"
  if (el.tagName === "IMG" && el.complete && el.getAttribute("src") && el.naturalWidth === 0) return fail(el)
  if (!loaded(el)) box.classList.add("is-loading")
}

function done(el) {
  const box = boxFor(el)
  box?.classList.remove("is-loading")
  if (el.tagName === "IMG" && el.naturalWidth > 0) {
    el.hidden = false
    box?.querySelector(":scope > .img-fallback")?.remove()
    box?.classList.remove("is-failed")
  }
}

function fail(el) {
  const box = boxFor(el) || el.parentElement
  if (!box) return
  box.classList.remove("is-loading")
  if (box.querySelector(":scope > .img-fallback")) return
  const tpl = document.getElementById("illus-fallback")
  const holder = document.createElement("span")
  holder.className = "img-fallback"
  holder.innerHTML = tpl ? tpl.innerHTML : ""
  holder.title = "No se pudo cargar la imagen"
  if (box === el) {
    // La imagen es su propio contenedor (miniaturas): se reemplaza por la ilustración
    holder.classList.add(...[...el.classList].filter((c) => c !== "is-loading"))
    el.replaceWith(holder)
  } else {
    el.hidden = true
    box.classList.add("is-failed")
    box.appendChild(holder)
  }
}

function scan(root = document) {
  root.querySelectorAll("img, iframe").forEach(track)
}

export function installMediaState() {
  document.addEventListener("load", (e) => { if (e.target.tagName === "IMG" || e.target.tagName === "IFRAME") done(e.target) }, true)
  document.addEventListener("error", (e) => { if (e.target.tagName === "IMG") fail(e.target) }, true)
  document.addEventListener("turbo:load", () => scan())
  document.addEventListener("turbo:frame-load", (e) => scan(e.target))
  // Imágenes que se agregan o cambian después (visor, vista previa del QR)
  new MutationObserver((mutations) => {
    for (const m of mutations) {
      if (m.type === "attributes" && m.target.tagName === "IMG") {
        delete m.target.dataset.mediaTracked
        track(m.target)
      }
      m.addedNodes.forEach((n) => {
        if (n.nodeType !== 1) return
        if (n.matches?.("img, iframe")) track(n)
        n.querySelectorAll?.("img, iframe").forEach(track)
      })
    }
  }).observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ["src"] })
  if (document.readyState !== "loading") scan()
  else document.addEventListener("DOMContentLoaded", () => scan())
}
