# A real week-view time grid. Cards with a start time are positioned blocks
# (drag to move, resize to change duration); everything else sits in the
# Unscheduled sidebar until it's dragged onto the grid.
class CalendarController < ApplicationController
  START_HOUR = 6
  END_HOUR = 23

  def show
    @week_start = parse_week_start(params[:start])
    @days = (0..6).map { |offset| @week_start + offset }

    RecurringTask.generate_todays_tasks!(Current.user) if @days.include?(Date.current)

    tasks = Current.user.tasks.kept.where(status: %w[pending doing done]).includes(:subject, :topic)
    @scheduled_by_day = @days.index_with do |date|
      tasks.select { |task| task.scheduled_on == date && task.starts_at.present? }.sort_by(&:starts_at)
    end
    @unscheduled = tasks.select { |task| task.starts_at.nil? }.sort_by(&:calendar_position)
    @columns_by_task_id = @scheduled_by_day.values.flat_map { |day_tasks| layout_columns(day_tasks).to_a }.to_h
    @subjects = Current.user.subjects.active.includes(:topics)
    @start_hour = START_HOUR
    @end_hour = END_HOUR
  end

  private
    def parse_week_start(value)
      date = value.present? ? Date.iso8601(value) : Date.current
      date.beginning_of_week(:monday)
    rescue ArgumentError
      Date.current.beginning_of_week(:monday)
    end

    # Side-by-side layout for overlapping events, like a normal calendar:
    # each task gets a column index and the day's column count (simple
    # greedy coloring - a day with several small overlapping clusters gets
    # narrower columns than strictly necessary, but nothing ever hides
    # behind something else).
    def layout_columns(day_tasks)
      column_ends = []
      assignment = day_tasks.each_with_object({}) do |task, result|
        finish = task.starts_at + (task.estimate_minutes || 30).minutes
        column = column_ends.index { |end_time| end_time <= task.starts_at }
        column ||= column_ends.size
        column_ends[column] = finish
        result[task.id] = column
      end
      total = column_ends.size
      assignment.transform_values { |column| [ column, total ] }
    end
end
