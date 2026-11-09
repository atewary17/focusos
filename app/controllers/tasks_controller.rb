class TasksController < ApplicationController
  before_action :set_task, only: %i[update destroy]

  def create
    @task = Current.user.tasks.build(task_params)
    if @task.save
      redirect_to board_path, notice: "Added #{@task.title}."
    else
      redirect_to board_path, alert: @task.errors.full_messages.to_sentence
    end
  end

  def update
    @task.update(task_params)
    redirect_to board_path
  end

  def destroy
    @task.destroy
    redirect_to board_path
  end

  # Called after a drag-and-drop move: the whole board's lane/position state,
  # as { "backlog" => [id, …], "next" => [...], "today" => [...], "done" => [...] }.
  def reorder
    lanes = params.permit(lanes: Task::LANES.index_with { [] }).fetch(:lanes, {}).to_h
    Task.reorder_board!(Current.user, lanes)
    head :no_content
  end

  private
    def set_task
      @task = Current.user.tasks.find(params[:id])
    end

    def task_params
      params.fetch(:task, {}).permit(:title, :notes, :lane, :priority, :due_on, :estimate_minutes, :energy,
                                      :topic_id, :subject_id)
    end
end
