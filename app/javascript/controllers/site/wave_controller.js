import { Controller } from "@hotwired/stimulus"

// Barras del ecualizador del visual de podcast.
export default class extends Controller {
  connect() {
    if (this.element.childElementCount) return
    for (let i = 0; i < 36; i++) {
      const s = document.createElement("span")
      s.style.height = `${25 + Math.round(Math.abs(Math.sin(i * 0.55)) * 60 + (i * 7 % 15))}%`
      s.style.animationDelay = `${-(i % 9) * 0.17}s`
      s.style.animationDuration = `${1 + (i % 5) * 0.18}s`
      this.element.appendChild(s)
    }
  }
}
