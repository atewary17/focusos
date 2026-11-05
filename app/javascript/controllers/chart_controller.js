import { Controller } from "@hotwired/stimulus"

// Hover and keyboard-focus tooltip for the server-rendered charts.
// A mark sets data-tip-title and data-tip-rows (JSON [[name, value, color]]);
// all text is inserted with textContent.
export default class extends Controller {
  static targets = ["tooltip"]

  show(event) {
    const mark = event.currentTarget
    const tip = this.tooltipTarget
    tip.replaceChildren(this.#line(mark.dataset.tipTitle, "mb-1 text-stone-500"))

    JSON.parse(mark.dataset.tipRows || "[]").forEach(([name, value, color]) => {
      const row = document.createElement("div")
      row.className = "flex items-center gap-2"
      if (color) {
        const key = document.createElement("span")
        key.className = "inline-block h-0.5 w-3 shrink-0 rounded-full"
        key.style.background = color
        row.append(key)
      }
      row.append(this.#line(value, "font-semibold tabular-nums text-stone-900", "span"),
                 this.#line(name, "text-stone-500", "span"))
      tip.append(row)
    })

    tip.hidden = false
    const box = this.element.getBoundingClientRect()
    const anchor = (mark.querySelector("[data-tip-anchor]") || mark).getBoundingClientRect()
    const left = anchor.left + anchor.width / 2 - box.left - tip.offsetWidth / 2
    const top = anchor.top - box.top - tip.offsetHeight - 8
    tip.style.left = `${Math.max(0, Math.min(left, box.width - tip.offsetWidth))}px`
    tip.style.top = `${Math.max(0, top)}px`
  }

  hide() {
    this.tooltipTarget.hidden = true
  }

  #line(text, className, tag = "p") {
    const element = document.createElement(tag)
    element.className = className
    element.textContent = text
    return element
  }
}
