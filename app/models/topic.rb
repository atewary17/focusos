# A topic under a subject (e.g. "Indifference curves"); tasks are its sessions.
class Topic < ApplicationRecord
  STATUSES = %w[not_started in_progress done].freeze

  belongs_to :user
  belongs_to :subject
  has_many :tasks, dependent: :nullify

  before_validation :assign_position, on: :create
  before_validation :copy_user_from_subject, on: :create

  validates :name, presence: true, length: { maximum: 80 }
  validates :status, inclusion: { in: STATUSES }

  validates :estimated_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validate :subject_belongs_to_user

  def done_tasks_count = tasks.where(status: "done").count
  def tasks_count = tasks.count

  private
    def assign_position
      self.position = (subject&.topics&.maximum(:position) || -1) + 1
    end

    def copy_user_from_subject
      self.user ||= subject&.user
    end

    def subject_belongs_to_user
      errors.add(:subject, "must belong to you") if subject && user && subject.user_id != user_id
    end
end
