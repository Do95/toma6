// Modal de confirmación con la marca (reemplaza a window.confirm).
// Se usa con data-turbo-confirm="mensaje" y, opcionalmente:
//   data-confirm-title="Título"  data-confirm-button="Eliminar"  data-confirm-variant="danger|primary"
import { Turbo } from "@hotwired/turbo-rails"

let dialog

function build() {
  dialog = document.createElement("dialog")
  dialog.className = "cmodal"
  dialog.innerHTML = `
    <form method="dialog" class="cmodal-box">
      <div class="cmodal-icon" aria-hidden="true"></div>
      <h2 class="cmodal-title"></h2>
      <p class="cmodal-text"></p>
      <ul class="cmodal-list" hidden></ul>
      <div class="cmodal-actions">
        <button value="cancel" class="cmodal-cancel">Cancelar</button>
        <button value="ok" class="cmodal-ok">Confirmar</button>
      </div>
    </form>`
  dialog.addEventListener("click", (e) => { if (e.target === dialog) dialog.close("cancel") })
  document.body.appendChild(dialog)
}

const ICONS = {
  danger: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
  primary: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>',
  warning: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.7 18-8-14a2 2 0 0 0-3.4 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.7-3z"/><path d="M12 9v4M12 17h.01"/></svg>'
}

export function openConfirm({ message, title, button, variant = "danger", items = [] }) {
  if (!dialog || !dialog.isConnected) build()
  dialog.dataset.variant = variant
  dialog.querySelector(".cmodal-icon").innerHTML = ICONS[variant] || ICONS.danger
  dialog.querySelector(".cmodal-title").textContent = title || (variant === "danger" ? "¿Seguro?" : "Confirmar")
  dialog.querySelector(".cmodal-text").textContent = message || ""
  const list = dialog.querySelector(".cmodal-list")
  list.hidden = !items.length
  list.innerHTML = items.slice(0, 8).map((i) => `<li>${String(i).replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" })[c])}</li>`).join("") + (items.length > 8 ? `<li>y ${items.length - 8} más…</li>` : "")
  dialog.querySelector(".cmodal-ok").textContent = button || (variant === "danger" ? "Eliminar" : "Confirmar")
  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "ok"), { once: true })
    dialog.returnValue = ""
    dialog.showModal()
    dialog.querySelector(variant === "danger" ? ".cmodal-cancel" : ".cmodal-ok").focus()
  })
}

export function installConfirm() {
  const confirmMethod = (message, element, submitter) => {
    const src = (k) => submitter?.dataset?.[k] || element?.dataset?.[k]
    let items = []
    try { items = JSON.parse(src("confirmItems") || "[]") } catch (_) {}
    return openConfirm({ message, title: src("confirmTitle"), button: src("confirmButton"), variant: src("confirmVariant") || "danger", items })
  }
  if (Turbo.config?.forms) Turbo.config.forms.confirm = confirmMethod
  else Turbo.setConfirmMethod(confirmMethod)
}
