// Formularios del panel:
//  - "Guardar cambios" pide confirmación y muestra qué campos cambiaron.
//  - Si salís con cambios sin guardar, te avisa con un modal.
import { Turbo } from "@hotwired/turbo-rails"
import { openConfirm } from "lib/confirm"

const snapshots = new WeakMap()

function editableForms() {
  return [...document.querySelectorAll("form")].filter((f) =>
    f.querySelector(".form-actions, .sticky-actions") && !f.hasAttribute("data-no-guard"))
}

function serialize(form) {
  const data = {}
  for (const el of form.elements) {
    if (!el.name || el.type === "hidden" || el.type === "submit" || el.name === "authenticity_token") continue
    if ((el.type === "checkbox" || el.type === "radio") && !el.checked) continue
    data[el.name] = (data[el.name] ? data[el.name] + "|" : "") + (el.type === "file" ? (el.files.length ? `archivo:${el.files[0].name}` : "") : el.value)
  }
  return data
}

function labelFor(form, name) {
  const el = form.querySelector(`[name="${CSS.escape(name)}"]`)
  const label = (el?.id && form.querySelector(`label[for="${CSS.escape(el.id)}"]`)) || el?.closest(".field, .switch, .theme-picks, .network-picks")?.querySelector("label, .label, strong")
  const text = label?.textContent?.trim().replace(/\s+/g, " ")
  return text || name.replace(/^\w+\[|\]$/g, "").replace(/[_\]\[]+/g, " ")
}

function changes(form) {
  const before = snapshots.get(form) || {}
  const after = serialize(form)
  const keys = new Set([...Object.keys(before), ...Object.keys(after)])
  const names = [...keys].filter((k) => (before[k] || "") !== (after[k] || ""))
  return [...new Set(names.map((n) => labelFor(form, n)))]
}

function remember() {
  editableForms().forEach((f) => {
    snapshots.set(f, serialize(f))
    const isUpdate = f.querySelector('input[name="_method"][value="patch"], input[name="_method"][value="put"]')
    if (isUpdate) f.dataset.guardUpdate = "1"
  })
}

function dirtyForms() { return editableForms().filter((f) => snapshots.has(f) && changes(f).length) }

export function installAdminForms() {
  document.addEventListener("turbo:load", remember)

  // Confirmar "Guardar cambios" en formularios de edición
  document.addEventListener("submit", async (event) => {
    const form = event.target
    if (!form.dataset.guardUpdate || form.dataset.confirmed === "1") return
    event.preventDefault()
    event.stopImmediatePropagation()
    const changed = changes(form)
    const ok = await openConfirm({
      variant: "primary",
      title: "¿Guardar los cambios?",
      message: changed.length ? "Vas a guardar cambios en:" : "No modificaste ningún campo. ¿Querés guardar igual?",
      items: changed,
      button: "Guardar cambios"
    })
    if (!ok) return
    form.dataset.confirmed = "1"
    snapshots.set(form, serialize(form))
    form.requestSubmit(event.submitter)
    setTimeout(() => { delete form.dataset.confirmed }, 1000)
  }, true)

  // Avisar antes de salir con cambios sin guardar
  document.addEventListener("turbo:before-visit", async (event) => {
    const dirty = dirtyForms()
    if (!dirty.length || window.__leavingConfirmed) return
    event.preventDefault()
    const ok = await openConfirm({
      variant: "warning",
      title: "Tenés cambios sin guardar",
      message: "Si salís ahora se pierden estos cambios:",
      items: dirty.flatMap(changes),
      button: "Salir sin guardar"
    })
    if (ok) {
      window.__leavingConfirmed = true
      Turbo.visit(event.detail.url)
      setTimeout(() => { window.__leavingConfirmed = false }, 500)
    }
  })
  window.addEventListener("beforeunload", (e) => {
    if (dirtyForms().length && !window.__leavingConfirmed) { e.preventDefault(); e.returnValue = "" }
  })
  // Al enviar un formulario, deja de contar como "sin guardar"
  document.addEventListener("turbo:submit-start", (e) => snapshots.set(e.target, serialize(e.target)))
}
