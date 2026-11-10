# Subtasks are a small checklist stored on the task (no separate table), so
# "subtask_id" here is its index in that array.
class TaskSubtasksController < ApplicationController
  before_action :set_task

  def create
    text = params.require(:text)
    @task.add_subtask!(text) if text.present?
    redirect_to plan_path
  end

  def toggle
    @task.toggle_subtask!(params[:subtask_id].to_i)
    redirect_to plan_path
  end

  def destroy
    @task.remove_subtask!(params[:subtask_id].to_i)
    redirect_to plan_path
  end

  private
    def set_task
      @task = Current.user.tasks.find(params[:task_id])
    end
end
