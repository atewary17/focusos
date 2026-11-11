import { Controller } from "@hotwired/stimulus"

// A real time grid: event blocks are dragged to move (change day/time) or
// resized (change duration), sidebar cards are dragged onto the grid to
// schedule them, and clicking empty space on a day adds a card right there.
// Pointer Events (not HTML5 drag-and-drop or SortableJS) so free-form grid
// placement works the same with touch and mouse.
export default class extends Controller {
  static targets = ["day", "sidebar"]
  static values = { startHour: Number, endHour: Number, rescheduleUrlTemplate: String,
                     updateUrlTemplate: String, createUrl: String }

  static PX_PER_MIN = 1
  static SNAP_MIN = 15
  static DRAG_THRESHOLD_PX = 4

  connect() {
    this.element.querySelectorAll('[data-calendar-target="event"]').forEach((el) => this.#bindMove(el, false))
    this.sidebarTarget.querySelectorAll("[data-task-id]").forEach((el) => this.#bindMove(el, true))
    this.element.querySelectorAll("[data-calendar-resize]").forEach((handle) => this.#bindResize(handle))
    this.dayTargets.forEach((day) => day.addEventListener("click", (event) => this.#onDayClick(event, day)))
    this.tooltip = this.#buildTooltip()
    this.#drawNowLine()
    this.nowInterval = setInterval(() => this.#drawNowLine(), 60_000)
  }

  disconnect() {
    clearInterval(this.nowInterval)
  }

  // ------------------------------------------------------------ click to add

  #onDayClick(event, day) {
    if (event.target.closest('[data-calendar-target="event"]') || event.target.closest("form")) return
    this.#closeQuickAdd()

    const time = this.#timeFromY(day, event.clientY)
    const form = this.#quickAddForm(day.dataset.date, time.text)
    form.style.top = `${Math.min(time.minutes, day.getBoundingClientRect().height - 40)}px`
    day.appendChild(form)
    form.querySelector("input[type=text]").focus()
  }

  #quickAddForm(date, timeText) {
    const form = document.createElement("form")
    form.action = this.createUrlValue
    form.method = "post"
    form.className = "absolute left-0.5 right-0.5 z-20 flex items-center gap-1 rounded-md border border-teal-600 bg-white p-1 shadow-lg"
    form.innerHTML = `
      <input type="hidden" name="authenticity_token" value="${this.#csrfToken()}">
      <input type="hidden" name="task[scheduled_on]" value="${date}">
      <input type="hidden" name="task[starts_time]" value="${timeText}">
      <input type="hidden" name="return_to" value="calendar">
      <input type="text" name="task[title]" placeholder="New card at ${this.#displayTime(timeText)}…" required
             class="min-w-0 flex-1 border-0 p-0.5 text-xs focus:outline-none focus:ring-0">
    `
    form.addEventListener("click", (e) => e.stopPropagation())
    form.addEventListener("keydown", (e) => {
      if (e.key === "Escape") this.#closeQuickAdd()
      if (e.key === "Enter") { e.preventDefault(); form.requestSubmit() }
    })
    this.boundCloseOnOutsideClick = this.boundCloseOnOutsideClick || ((e) => {
      if (this.openQuickAddForm && !this.openQuickAddForm.contains(e.target)) this.#closeQuickAdd()
    })
    // Deferred: the click that opened this form is still bubbling up to
    // document right now, and would otherwise be seen as the "outside"
    // click that immediately closes what it just opened.
    setTimeout(() => document.addEventListener("click", this.boundCloseOnOutsideClick), 0)
    this.openQuickAddForm = form
    return form
  }

  #closeQuickAdd() {
    this.openQuickAddForm?.remove()
    this.openQuickAddForm = null
    if (this.boundCloseOnOutsideClick) document.removeEventListener("click", this.boundCloseOnOutsideClick)
  }

  #displayTime(timeText) {
    const [ hour, minute ] = timeText.split(":").map(Number)
    const period = hour < 12 ? "am" : "pm"
    const displayHour = hour % 12 === 0 ? 12 : hour % 12
    return `${displayHour}:${String(minute).padStart(2, "0")} ${period}`
  }

  // ------------------------------------------------------------------ "now"

  #drawNowLine() {
    this.element.querySelectorAll("[data-calendar-now-line]").forEach((el) => el.remove())
    const now = new Date()
    const minutes = now.getHours() * 60 + now.getMinutes() - this.startHourValue * 60
    if (minutes < 0 || minutes > (this.endHourValue - this.startHourValue) * 60) return

    const today = this.dayTargets.find((day) => day.dataset.today === "true")
    if (!today) return

    const line = document.createElement("div")
    line.dataset.calendarNowLine = ""
    line.className = "pointer-events-none absolute inset-x-0 z-10 border-t-2 border-red-400"
    line.style.top = `${minutes}px`
    const dot = document.createElement("span")
    dot.className = "absolute -left-1 -top-1 h-2 w-2 rounded-full bg-red-400"
    line.appendChild(dot)
    today.appendChild(line)
  }

  // --------------------------------------------------------------- dragging

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
    let hoveredDay = null

    const onMove = (event) => {
      if (!dragging) {
        if (Math.hypot(event.clientX - startX, event.clientY - startY) < this.constructor.DRAG_THRESHOLD_PX) return
        dragging = true
        this.#closeQuickAdd()
        dragEl = fromSidebar ? this.#ghostFor(el, rect.width) : el
        dragEl.style.position = "fixed"
        dragEl.style.zIndex = "50"
        dragEl.style.width = `${rect.width}px`
        dragEl.style.pointerEvents = "none"
        dragEl.style.opacity = "0.9"
        dragEl.classList.add("shadow-xl", "ring-2", "ring-white")
        if (fromSidebar) document.body.appendChild(dragEl)
        this.tooltip.hidden = false
      }
      dragEl.style.left = `${event.clientX - grabOffsetX}px`
      dragEl.style.top = `${event.clientY - grabOffsetY}px`

      const day = this.#dayUnderPoint(event.clientX, event.clientY)
      if (day !== hoveredDay) {
        hoveredDay?.classList.remove("bg-teal-50")
        day?.classList.add("bg-teal-50")
        hoveredDay = day
      }
      this.#moveTooltip(event.clientX, event.clientY, day ? this.#timeFromY(day, event.clientY - grabOffsetY) : null)
    }

    const onUp = (event) => {
      document.removeEventListener("pointermove", onMove)
      document.removeEventListener("pointerup", onUp)
      hoveredDay?.classList.remove("bg-teal-50")
      this.tooltip.hidden = true
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
      dragEl.classList.remove("shadow-xl", "ring-2", "ring-white")

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
      this.tooltip.hidden = false
      block.classList.add("shadow-xl")

      const onMove = (event) => {
        const delta = event.clientY - startY
        const height = Math.max(this.constructor.SNAP_MIN, this.#snap(startHeight + delta))
        block.style.height = `${height}px`
        this.#moveTooltip(event.clientX, event.clientY, { text: `${height}m` })
      }

      const onUp = () => {
        document.removeEventListener("pointermove", onMove)
        document.removeEventListener("pointerup", onUp)
        this.tooltip.hidden = true
        block.classList.remove("shadow-xl")
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
    const text = `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`
    return { minutes, text, display: this.#displayTime(text) }
  }

  // ----------------------------------------------------------- the tooltip

  #buildTooltip() {
    const el = document.createElement("div")
    el.hidden = true
    el.className = "pointer-events-none fixed z-50 rounded bg-stone-900 px-2 py-1 text-xs font-medium text-white shadow-lg"
    document.body.appendChild(el)
    return el
  }

  #moveTooltip(x, y, time) {
    if (!time) { this.tooltip.hidden = true; return }
    this.tooltip.hidden = false
    this.tooltip.textContent = time.display || time.text
    this.tooltip.style.left = `${x + 14}px`
    this.tooltip.style.top = `${y + 14}px`
  }

  // --------------------------------------------------------------- network

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
