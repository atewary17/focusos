# Helpers for the server-rendered dashboard charts (app/views/charts/*).
# Colors come from the CSS variables in app/assets/tailwind/application.css.
module ChartsHelper
  PLOT_HEIGHT = 160
  MINUTE_STEPS = [ 5, 10, 15, 30, 60, 90, 120, 180, 240, 360, 480, 720 ].freeze
  # Upper bounds (minutes) for the heatmap's sequential color steps 1..5; 0 is step 0.
  HEAT_STEPS = [ 5, 15, 30, 45, 60 ].freeze

  # Axis top and tick step for values up to `max`, using `steps` (minutes) or 1-2-5 numbers.
  def nice_scale(max, ticks: 4, steps: nil)
    max = max.to_f
    return [ steps ? steps.first * ticks : ticks, steps ? steps.first : 1 ] if max <= 0

    raw = max / ticks
    step = if steps
      steps.find { |candidate| candidate >= raw } || (raw / steps.last).ceil * steps.last
    else
      magnitude = 10**Math.log10(raw).floor
      [ 1, 2, 5, 10 ].map { |factor| factor * magnitude }.find { |candidate| candidate >= raw }
    end
    [ step * ticks, step ]
  end

  # 125 → "2h 05m", 45 → "45m"
  def duration_label(minutes)
    minutes = minutes.to_i
    minutes >= 60 ? format("%dh %02dm", minutes / 60, minutes % 60) : "#{minutes}m"
  end

  # Axis ticks: 0, 30m, 1h, 1.5h, 2h
  def axis_duration(minutes)
    return "#{minutes}m" if minutes < 60

    hours = minutes / 60.0
    "#{hours % 1 == 0 ? hours.to_i : hours.round(1)}h"
  end

  def chart_date(date)
    date == Date.current ? "Today" : date.strftime("%a %-d")
  end

  # Label every day for a week; every fifth day and the last one for a month.
  def show_tick?(index, count)
    count <= 7 || (index % 5).zero? && index <= count - 3 || index == count - 1
  end

  def heat_color(minutes)
    level = minutes.to_i.zero? ? 0 : (HEAT_STEPS.index { |bound| minutes <= bound } || HEAT_STEPS.size - 1) + 1
    "var(--viz-seq-#{level})"
  end

  def hour_label(hour)
    Time.zone.local(2000, 1, 1, hour).strftime("%-l%P")
  end

  # JSON for the chart tooltip: [[series name, formatted value, color or nil], …]
  def tip_rows(rows)
    rows.to_json
  end
end
