import { Controller } from "@hotwired/stimulus"

// A real time grid: event blocks are dragged to move (change day/time) or
// resized (change duration), and sidebar cards are dragged onto the grid to
// schedule them. Pointer Events (not HTML5 drag-and-drop) so it works the
// same with touch and mouse.
export default class extends Controller {
  static targets = ["day", "sidebar"]
  static values = { startHour: Number, rescheduleUrlTemplate: String, updateUrlTemplate: String }

  static PX_PER_MIN = 1
  static SNAP_MIN = 15
  static DRAG_THRESHOLD_PX = 4

  connect() {
    this.element.querySelectorAll('[data-calendar-target="event"]').forEach((el) => this.#bindMove(el, false))
    this.sidebarTarget.querySelectorAll("[data-task-id]").forEach((el) => this.#bindMove(el, true))
    this.element.querySelectorAll("[data-calendar-resize]").forEach((handle) => this.#bindResize(handle))
  }

  #bindMove(el, fromSidebar) {
    el.addEventListener("pointerdown", (event) => {
      if (event.target.closest("button") || event.target.closest("[data-calendar-resize]")) return
      this.#startMove(event, el, fromSidebar)
    })
  }

  #startMove(startEvent, el, fromSidebar) {
    const taskId = el.dataset.taskId
    const startX = startEvent.clientX
    const startY = startEvent.clientY
    const rect = el.getBoundingClientRect()
    const grabOffsetY = startY - rect.top
    const grabOffsetX = startX - rect.left
    const originalTop = el.style.top
    let dragging = false
    let dragEl = null

    const onMove = (event) => {
      if (!dragging) {
        if (Math.hypot(event.clientX - startX, event.clientY - startY) < this.constructor.DRAG_THRESHOLD_PX) return
        dragging = true
        dragEl = fromSidebar ? this.#ghostFor(el, rect.width) : el
        dragEl.style.position = "fixed"
        dragEl.style.zIndex = "50"
        dragEl.style.width = `${rect.width}px`
        dragEl.style.pointerEvents = "none"
        dragEl.style.opacity = "0.9"
        if (fromSidebar) document.body.appendChild(dragEl)
      }
      dragEl.style.left = `${event.clientX - grabOffsetX}px`
      dragEl.style.top = `${event.clientY - grabOffsetY}px`
    }

    const onUp = (event) => {
      document.removeEventListener("pointermove", onMove)
      document.removeEventListener("pointerup", onUp)
      if (!dragging) return

      const day = this.#dayUnderPoint(event.clientX, event.clientY)
      const dropY = event.clientY - grabOffsetY

      if (fromSidebar) {
        dragEl.remove()
        if (day) this.#reschedule(taskId, day, dropY, null, true)
        return
      }

      dragEl.style.position = ""
      dragEl.style.zIndex = ""
      dragEl.style.pointerEvents = ""
      dragEl.style.width = ""
      dragEl.style.opacity = ""
      dragEl.style.left = ""

      if (day) {
        this.#reschedule(taskId, day, dropY, dragEl, false)
      } else if (this.#overSidebar(event.clientX, event.clientY)) {
        dragEl.remove()
        this.#unschedule(taskId)
      } else {
        dragEl.style.top = originalTop
      }
    }

    document.addEventListener("pointermove", onMove)
    document.addEventListener("pointerup", onUp)
  }

  #bindResize(handle) {
    handle.addEventListener("pointerdown", (startEvent) => {
      startEvent.preventDefault()
      startEvent.stopPropagation()
      const block = handle.closest('[data-calendar-target="event"]')
      const taskId = block.dataset.taskId
      const startHeight = block.getBoundingClientRect().height
      const startY = startEvent.clientY

      const onMove = (event) => {
        const delta = event.clientY - startY
        const height = Math.max(this.constructor.SNAP_MIN, this.#snap(startHeight + delta))
        block.style.height = `${height}px`
      }

      const onUp = () => {
        document.removeEventListener("pointermove", onMove)
        document.removeEventListener("pointerup", onUp)
        const minutes = Math.max(this.constructor.SNAP_MIN, this.#snap(block.getBoundingClientRect().height))
        block.dataset.duration = minutes
        this.#updateDuration(taskId, minutes)
      }

      document.addEventListener("pointermove", onMove)
      document.addEventListener("pointerup", onUp)
    })
  }

  #dayUnderPoint(x, y) {
    const el = document.elementFromPoint(x, y)
    return el?.closest('[data-calendar-target="day"]') || null
  }

  #overSidebar(x, y) {
    return !!document.elementFromPoint(x, y)?.closest('[data-calendar-target="sidebar"]')
  }

  #ghostFor(el, width) {
    const clone = el.cloneNode(true)
    clone.style.width = `${width}px`
    return clone
  }

  #snap(minutes) {
    return Math.round(minutes / this.constructor.SNAP_MIN) * this.constructor.SNAP_MIN
  }

  // `topY`: the viewport Y where the block's top edge should land (already
  // adjusted for where in the block the pointer grabbed it).
  #timeFromY(day, topY) {
    const rect = day.getBoundingClientRect()
    const offset = Math.max(0, Math.min(topY - rect.top, rect.height))
    const minutes = this.#snap(offset / this.constructor.PX_PER_MIN)
    const hour = this.startHourValue + Math.floor(minutes / 60)
    const minute = minutes % 60
    return { minutes, text: `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}` }
  }

  // `movedEl`: the real event block to reposition live (grid-to-grid move);
  // null when there's no existing block to reuse (a sidebar card just got
  // scheduled), in which case a reload picks up the server-rendered block.
  #reschedule(taskId, day, topY, movedEl, fromSidebar) {
    const time = this.#timeFromY(day, topY)

    if (movedEl) {
      day.appendChild(movedEl)
      movedEl.style.top = `${time.minutes}px`
    }

    const url = this.rescheduleUrlTemplateValue.replace("/0/reschedule", `/${taskId}/reschedule`)
    fetch(url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.#csrfToken(), Accept: "application/json" },
      body: JSON.stringify({ scheduled_on: day.dataset.date, starts_time: time.text }),
    }).then((response) => {
      if (!response.ok || fromSidebar) window.location.reload()
    })
  }

  #unschedule(taskId) {
    const url = this.rescheduleUrlTemplateValue.replace("/0/reschedule", `/${taskId}/reschedule`)
    fetch(url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.#csrfToken(), Accept: "application/json" },
      body: JSON.stringify({ scheduled_on: "", starts_time: "" }),
    }).then(() => window.location.reload())
  }

  #updateDuration(taskId, minutes) {
    const url = this.updateUrlTemplateValue.replace(/\/0$/, `/${taskId}`)
    fetch(url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.#csrfToken(), Accept: "application/json" },
      body: JSON.stringify({ task: { estimate_minutes: minutes } }),
    })
  }

  #csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
