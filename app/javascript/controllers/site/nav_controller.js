import { Controller } from "@hotwired/stimulus"

// Menú móvil y barra que se compacta al hacer scroll.
export default class extends Controller {
  static targets = ["bar", "menu", "toggle"]

  connect() {
    this.onScroll = () => this.barTarget.classList.toggle("is-scrolled", window.scrollY > 24)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    document.body.classList.remove("menu-open")
  }

  toggle() {
    const open = !document.body.classList.contains("menu-open")
    document.body.classList.toggle("menu-open", open)
    this.toggleTarget.setAttribute("aria-expanded", String(open))
  }

  close(event) {
    if (event?.target?.closest && !event.target.closest("a")) return
    document.body.classList.remove("menu-open")
    this.toggleTarget?.setAttribute("aria-expanded", "false")
  }

  menuTargetConnected(menu) {
    menu.addEventListener("click", (e) => this.close(e))
  }
}
