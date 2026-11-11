# "Add items and sub-items": subjects and their topics, managed before the
# board where tasks get dragged around.
class SubjectsController < ApplicationController
  before_action :set_subject, only: %i[update destroy]

  def index
    @subjects = Current.user.subjects.active.includes(:topics)
    @archived_subjects = Current.user.subjects.where.not(archived_at: nil).order(:position)
    @subject = Subject.new
  end

  def create
    @subject = Current.user.subjects.build(subject_params)
    if @subject.save
      redirect_to subjects_path, notice: "Added #{@subject.name}."
    else
      @subjects = Current.user.subjects.active.includes(:topics)
      @archived_subjects = Current.user.subjects.where.not(archived_at: nil).order(:position)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @subject.update(subject_params.merge(archived_toggle_params))
      redirect_to subjects_path, notice: "Updated #{@subject.name}."
    else
      redirect_to subjects_path, alert: @subject.errors.full_messages.to_sentence
    end
  end

  def destroy
    @subject.destroy
    redirect_to subjects_path, notice: "Removed #{@subject.name}."
  end

  private
    def set_subject
      @subject = Current.user.subjects.find(params[:id])
    end

    def subject_params
      params.fetch(:subject, {}).permit(:name, :color, :weekly_target_minutes)
    end

    # The archive/unarchive buttons submit a single field with no other params.
    def archived_toggle_params
      return {} unless params[:subject]&.key?(:archived)

      { archived_at: ActiveModel::Type::Boolean.new.cast(params[:subject][:archived]) ? Time.current : nil }
    end
end
