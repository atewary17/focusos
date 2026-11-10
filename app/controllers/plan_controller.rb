# The day planner: an Unscheduled pool plus a few day columns, each a
# drop target for drag-and-drop, with a hint of a timeline for today.
class PlanController < ApplicationController
  DAYS_SHOWN = 3
  DAY_CAPACITY_MINUTES = 480 # 8 hours; shown as the progress bar's full width

  def show
    tasks = Current.user.tasks.includes(:subject, :topic).where(status: %w[pending done])
    @days = (0...DAYS_SHOWN).map { |offset| Date.current + offset }
    @unscheduled = tasks.select { |task| task.scheduled_on.nil? }.sort_by(&:position)
    @tasks_by_day = @days.index_with { |date| tasks.select { |task| task.scheduled_on == date }.sort_by(&:position) }
    @minutes_by_day = @tasks_by_day.transform_values { |day_tasks| day_tasks.sum { |task| task.estimate_minutes || 0 } }
    @day_capacity_minutes = DAY_CAPACITY_MINUTES
    @timeline_tasks = @tasks_by_day[Date.current].select(&:starts_at).sort_by(&:starts_at)
    @subjects = Current.user.subjects.active.includes(:topics)
  end
end
