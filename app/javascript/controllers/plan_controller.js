import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// The day planner: one Sortable list per column (Unscheduled + each day),
// all in the same group so cards can be dragged onto a different day. Any
// drop anywhere posts the full board state (every column's card ids, in
// order) to persist it.
export default class extends Controller {
  static targets = ["column"]

  connect() {
    this.sortables = this.columnTargets.map((column) => new Sortable(column, {
      group: "plan",
      animation: 150,
      ghostClass: "opacity-40",
      dragClass: "shadow-lg",
      delay: 120,
      delayOnTouchOnly: true,
      touchStartThreshold: 4,
      fallbackOnBody: true,
      invertSwap: true,
      emptyInsertThreshold: 24,
      onEnd: () => this.#persist(),
    }))
  }

  disconnect() {
    this.sortables?.forEach((sortable) => sortable.destroy())
  }

  #persist() {
    const days = {}
    this.columnTargets.forEach((column) => {
      days[column.dataset.day] = Array.from(column.children).map((card) => card.dataset.taskId)
    })

    fetch(this.element.dataset.reorderUrl, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json",
      },
      body: JSON.stringify({ days }),
    })
  }
}
