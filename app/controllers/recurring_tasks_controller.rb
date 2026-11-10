class RecurringTasksController < ApplicationController
  before_action :set_recurring_task, only: %i[update destroy toggle]

  def create
    recurring_task = Current.user.recurring_tasks.build(recurring_task_params)
    if recurring_task.save
      redirect_to board_path, notice: "Added #{recurring_task.title}."
    else
      redirect_to board_path, alert: recurring_task.errors.full_messages.to_sentence
    end
  end

  def update
    @recurring_task.update(recurring_task_params)
    redirect_to board_path
  end

  def toggle
    @recurring_task.update(active: !@recurring_task.active?)
    redirect_to board_path
  end

  def destroy
    @recurring_task.destroy
    redirect_to board_path, notice: "Removed #{@recurring_task.title}."
  end

  private
    def set_recurring_task
      @recurring_task = Current.user.recurring_tasks.find(params[:id])
    end

    def recurring_task_params
      permitted = params.fetch(:recurring_task, {}).permit(:title, :estimate_minutes, :priority, :energy,
                                                             :topic_id, :subject_id, days_of_week: [])
      permitted[:days_of_week] = Array(permitted[:days_of_week]).compact_blank.map(&:to_i) if permitted.key?(:days_of_week)
      permitted
    end
end
