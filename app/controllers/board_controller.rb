class BoardController < ApplicationController
  def show
    tasks = Current.user.tasks.includes(:subject, :topic)
    @lanes = Task::LANES.index_with { |lane| tasks.select { |task| task.lane == lane }.sort_by(&:position) }
    @subjects = Current.user.subjects.active.includes(:topics)
    @task = Task.new
  end
end
