class TasksController < ApplicationController
  before_action :set_task, only: %i[update destroy toggle]

  def create
    @task = Current.user.tasks.build(task_params)
    if @task.save
      redirect_to plan_path, notice: "Added #{@task.title}."
    else
      redirect_to plan_path, alert: @task.errors.full_messages.to_sentence
    end
  end

  def update
    @task.update(task_params)
    redirect_to plan_path
  end

  def toggle
    @task.toggle_done!
    redirect_to plan_path
  end

  def destroy
    @task.destroy
    redirect_to plan_path
  end

  # Called after a drag-and-drop move: the whole planner's day/position
  # state, as { "unscheduled" | "2026-11-10" => [id, …], … }.
  def reorder
    raw_days = params[:days]
    days = raw_days.is_a?(ActionController::Parameters) ? raw_days.to_unsafe_h : {}
    days = days.transform_values { |ids| Array(ids) }
    unless days.keys.all? { |key| valid_day_key?(key) }
      return render json: { error: "invalid day" }, status: :unprocessable_entity
    end

    Task.reorder_board!(Current.user, days)
    head :no_content
  end

  private
    def set_task
      @task = Current.user.tasks.find(params[:id])
    end

    def task_params
      permitted = params.fetch(:task, {}).permit(:title, :notes, :priority, :due_on, :estimate_minutes, :energy,
                                                  :topic_id, :subject_id, :scheduled_on, :starts_time)
      starts_time = permitted.delete(:starts_time)
      if starts_time.present? && permitted[:scheduled_on].present?
        permitted[:starts_at] = "#{permitted[:scheduled_on]} #{starts_time}"
      end
      permitted
    end

    def valid_day_key?(key)
      return true if key == "unscheduled"

      Date.iso8601(key)
      true
    rescue ArgumentError
      false
    end
end
