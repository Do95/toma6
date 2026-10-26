import { Controller } from "@hotwired/stimulus"

// Captcha de Cloudflare Turnstile (solo aparece si está configurado en el servidor).
// El script se carga una sola vez y el widget se dibuja en cada visita (Turbo).
let loading = null
function loadTurnstile() {
  if (window.turnstile) return Promise.resolve(window.turnstile)
  loading ||= new Promise((resolve, reject) => {
    const s = document.createElement("script")
    s.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"
    s.async = true
    s.onload = () => resolve(window.turnstile)
    s.onerror = reject
    document.head.appendChild(s)
  })
  return loading
}

export default class extends Controller {
  static values = { siteKey: String }

  async connect() {
    try {
      const turnstile = await loadTurnstile()
      if (!this.element.isConnected) return
      this.widgetId = turnstile.render(this.element, { sitekey: this.siteKeyValue, language: "es", theme: "light", size: "flexible" })
    } catch {
      // No cargó: el envío llega sin token y el servidor pide volver a intentarlo
    }
  }

  disconnect() {
    if (this.widgetId !== undefined) window.turnstile?.remove(this.widgetId)
  }
}
