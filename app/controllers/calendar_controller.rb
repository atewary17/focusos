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
end
