import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// The backlog board: one Sortable list per lane, all in the same group so
// cards can be dragged between lanes. Any drop anywhere posts the full
// board state (every lane's card ids, in order) to persist it.
export default class extends Controller {
  static targets = ["lane"]

  connect() {
    this.sortables = this.laneTargets.map((lane) => new Sortable(lane, {
      group: "board",
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
    const lanes = {}
    this.laneTargets.forEach((lane) => {
      lanes[lane.dataset.lane] = Array.from(lane.children).map((card) => card.dataset.taskId)
    })

    fetch(this.element.dataset.reorderUrl, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json",
      },
      body: JSON.stringify({ lanes }),
    })
  }
}
