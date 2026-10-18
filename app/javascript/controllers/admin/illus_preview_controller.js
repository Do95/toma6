import { Controller } from "@hotwired/stimulus"

// Muestra en la cabecera de la columna la ilustración elegida.
export default class extends Controller {
  static targets = ["thumb", "title"]

  pick(event) {
    const tile = event.target.closest(".illus-opt")?.querySelector(".illus-tile")
    const svg = tile?.querySelector("svg")
    if (!this.hasThumbTarget) return
    if (this.thumbTarget.querySelector("img")) return // si hay foto, manda la foto
    this.thumbTarget.innerHTML = svg ? svg.outerHTML : ""
    this.thumbTarget.animate?.([{ transform: "scale(.8)" }, { transform: "scale(1)" }], { duration: 200 })
  }
}
