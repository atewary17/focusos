class TasksController < ApplicationController
  before_action :set_task, only: %i[update destroy toggle restore reschedule]

  def create
    @task = Current.user.tasks.build(task_params)
    if @task.save
      redirect_back_to_planner notice: "Added #{@task.title}."
    else
      redirect_back_to_planner alert: @task.errors.full_messages.to_sentence
    end
  end

  def update
    @task.update(task_params)
    redirect_back_to_planner
  end

  def toggle
    @task.toggle_done!
    redirect_back_to_planner
  end

  def destroy
    @task.soft_delete!
    redirect_back_to_planner notice: "Removed “#{@task.title}”.", undo_url: restore_task_path(@task)
  end

  def restore
    @task.restore!
    redirect_back_to_planner notice: "Restored “#{@task.title}”."
  end

  # Wipes every card the user has, scheduled or not. A hard delete, not
  # soft: clearing everything is a deliberate reset, not a single mistake
  # to offer "Undo" on.
  def destroy_all
    count = Current.user.tasks.count
    Current.user.tasks.destroy_all
    redirect_back_to_planner notice: "Removed all #{count} card(s)."
  end

  # Calendar drag: moves one card onto a specific day and time (JSON, no
  # redirect - the grid updates itself during the drag).
  def reschedule
    date = params[:scheduled_on].present? ? Date.iso8601(params[:scheduled_on]) : nil
    time = params[:starts_time].present? ? Time.zone.parse(params[:starts_time]) : nil
    @task.reschedule!(date, time)
    head :no_content
  rescue ArgumentError
    render json: { error: "invalid date or time" }, status: :unprocessable_entity
  end

  # Calendar's Unscheduled sidebar: the ordered list of card ids, as a
  # plain array (that list has no sub-groups, unlike the day/status boards).
  def reorder
    ids = Array(params[:ids])
    ids.each_with_index { |id, index| Current.user.tasks.where(id: id).update_all(calendar_position: index) }
    head :no_content
  end

  # Board drag: the whole status board's lane/position state, as
  # { "pending" | "doing" | "done" => [id, …], … }.
  def reorder_status
    raw_statuses = params[:statuses]
    statuses = raw_statuses.is_a?(ActionController::Parameters) ? raw_statuses.to_unsafe_h : {}
    statuses = statuses.transform_values { |ids| Array(ids) }
    unless statuses.keys.all? { |key| BoardController::STATUSES.include?(key) }
      return render json: { error: "invalid status" }, status: :unprocessable_entity
    end

    Task.reorder_board!(Current.user, statuses)
    head :no_content
  end

  private
    def set_task
      @task = Current.user.tasks.find(params[:id])
    end

    def task_params
      permitted = params.fetch(:task, {}).permit(:title, :notes, :status, :priority, :due_on, :estimate_minutes,
                                                  :energy, :topic_id, :subject_id, :scheduled_on, :starts_time)
      starts_time = permitted.delete(:starts_time)
      if starts_time.present? && permitted[:scheduled_on].present?
        permitted[:starts_at] = "#{permitted[:scheduled_on]} #{starts_time}"
      end
      permitted
    end

    # Both the Board and the Calendar can create/update/delete a card;
    # each quick-add/card form carries where to return to.
    def redirect_back_to_planner(notice: nil, alert: nil, undo_url: nil)
      path = params[:return_to] == "calendar" ? calendar_path : board_path
      redirect_to path, notice: notice, alert: alert, flash: { undo_url: undo_url }
    end
end
