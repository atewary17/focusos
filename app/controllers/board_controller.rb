# The status board: To-do / Doing / Done lanes, plus a Recurring lane that
# manages templates rather than cards. Dragging between the first three
# lanes changes a card's status.
class BoardController < ApplicationController
  STATUSES = %w[pending doing done].freeze

  def show
    RecurringTask.generate_todays_tasks!(Current.user)

    tasks = Current.user.tasks.kept.includes(:subject, :topic).where(status: STATUSES)
    @lanes = STATUSES.index_with { |status| tasks.select { |task| task.status == status }.sort_by(&:board_position) }
    @recurring_tasks = Current.user.recurring_tasks.order(:position).includes(:subject, :topic)
    @subjects = Current.user.subjects.active.includes(:topics)
  end
end
