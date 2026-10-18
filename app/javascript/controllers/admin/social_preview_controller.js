import { Controller } from "@hotwired/stimulus"

// Vista previa en vivo de la publicación, con contador de caracteres de Instagram.
export default class extends Controller {
  static targets = ["body", "link", "file", "image", "text", "counter", "switch"]
  static values = { limit: { type: Number, default: 2200 } }

  connect() { this.update() }

  update() {
    const body = this.bodyTarget.value
    const link = this.hasLinkTarget ? this.linkTarget.value : ""
    const ig = this.mode === "instagram"
    this.textTarget.textContent = ig ? body : [body, link].filter(Boolean).join("\n\n")
    const n = body.length
    this.counterTarget.textContent = `${n} / ${this.limitValue}`
    this.counterTarget.classList.toggle("is-over", n > this.limitValue)
  }

  pickLibrary(event) {
    const src = event.target.dataset.src
    if (src) this.setImage(src)
    if (this.hasFileTarget) this.fileTarget.value = ""
  }

  pickFile(event) {
    const file = event.target.files?.[0]
    if (!file) return
    this.element.querySelectorAll("[name='social_post[media_item_id]']").forEach((r) => { r.checked = r.value === "" })
    this.setImage(URL.createObjectURL(file))
  }

  setImage(src) {
    this.imageTarget.innerHTML = `<img src="${src}" alt="">`
    this.imageTarget.firstChild.animate([{ opacity: 0, transform: "scale(1.04)" }, { opacity: 1, transform: "none" }], { duration: 300 })
  }

  network(event) {
    this.mode = event.currentTarget.dataset.network
    this.switchTargets.forEach((b) => b.setAttribute("aria-pressed", String(b === event.currentTarget)))
    this.element.querySelector(".preview-phone").dataset.network = this.mode
    this.update()
  }
}
