# A template that generates a Task for today the first time the Board or
# Calendar loads on a day it's active (days_of_week, 0 = Sunday like Ruby's
# Date#wday). No scheduled job: generation is lazy and idempotent, guarded
# by the unique index on tasks (recurring_task_id, scheduled_on).
class RecurringTask < ApplicationRecord
  DAYS = (0..6).freeze

  belongs_to :user
  belongs_to :topic, optional: true
  belongs_to :subject, optional: true
  has_many :tasks, dependent: :nullify

  before_validation :assign_position, on: :create
  before_validation :inherit_subject_from_topic

  validates :title, presence: true, length: { maximum: 200 }
  validates :estimate_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validates :priority, inclusion: { in: 1..3 }, allow_nil: true
  validates :energy, inclusion: { in: Task::ENERGIES }, allow_nil: true
  validates :days_of_week, presence: true
  validate :days_of_week_are_valid
  validate :topic_belongs_to_user
  validate :subject_belongs_to_user

  scope :active, -> { where(active: true).order(:position) }

  def due_today?(date = Date.current)
    active? && days_of_week.include?(date.wday)
  end

  # Idempotent: a second call on the same day returns the existing task
  # instead of raising on the unique index.
  def generate_for!(date)
    return unless due_today?(date)

    tasks.find_by(scheduled_on: date) || user.tasks.create!(
      title: title, topic: topic, subject: subject, estimate_minutes: estimate_minutes,
      priority: priority, energy: energy, scheduled_on: date, recurring_task: self
    )
  end

  def self.generate_todays_tasks!(user, date = Date.current)
    user.recurring_tasks.active.select { |rt| rt.due_today?(date) }.map { |rt| rt.generate_for!(date) }
  end

  private
    def assign_position
      self.position = (user&.recurring_tasks&.maximum(:position) || -1) + 1
    end

    def inherit_subject_from_topic
      self.subject_id ||= topic&.subject_id
    end

    def days_of_week_are_valid
      errors.add(:days_of_week, "must be between 0 and 6") unless Array(days_of_week).all? { |d| DAYS.cover?(d) }
    end

    def topic_belongs_to_user
      errors.add(:topic, "must belong to you") if topic && user && topic.user_id != user_id
    end

    def subject_belongs_to_user
      errors.add(:subject, "must belong to you") if subject && user && subject.user_id != user_id
    end
end
