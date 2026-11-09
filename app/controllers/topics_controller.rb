class TopicsController < ApplicationController
  def create
    subject = Current.user.subjects.find(params[:subject_id])
    topic = subject.topics.build(topic_params.merge(user: Current.user))
    if topic.save
      redirect_to subjects_path, notice: "Added #{topic.name}."
    else
      redirect_to subjects_path, alert: topic.errors.full_messages.to_sentence
    end
  end

  def update
    topic = Current.user.topics.find(params[:id])
    topic.update(topic_params)
    redirect_to subjects_path
  end

  def destroy
    Current.user.topics.find(params[:id]).destroy
    redirect_to subjects_path
  end

  private
    def topic_params
      params.fetch(:topic, {}).permit(:name, :status, :estimated_minutes)
    end
end
