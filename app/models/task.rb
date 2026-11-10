# A plan card. `scheduled_on` is nil for the Unscheduled pool, or a date for
# one of the day columns; `starts_at` is an optional specific time within
# that day, shown on the card and used to place it on the timeline.
class Task < ApplicationRecord
  STATUSES = %w[pending done skipped].freeze
  ENERGIES = %w[high low].freeze

  belongs_to :user
  belongs_to :topic, optional: true
  belongs_to :subject, optional: true
  belongs_to :carried_from, class_name: "Task", optional: true

  before_validation :assign_position, on: :create
  before_validation :inherit_subject_from_topic
  before_validation :align_starts_at_with_scheduled_on

  validates :title, presence: true, length: { maximum: 200 }
  validates :notes, length: { maximum: 2000 }
  validates :status, inclusion: { in: STATUSES }
  validates :energy, inclusion: { in: ENERGIES }, allow_nil: true
  validates :priority, inclusion: { in: 1..3 }, allow_nil: true
  validates :estimate_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validate :topic_belongs_to_user
  validate :subject_belongs_to_user

  scope :unscheduled, -> { where(scheduled_on: nil).order(:position) }
  scope :scheduled_on_date, ->(date) { where(scheduled_on: date).order(:position) }
  scope :kept, -> { where(deleted_at: nil) }

  # Moves every card into the given day (or the Unscheduled pool) and
  # position, in one transaction. `days` is { "unscheduled" | "2026-11-10" => [id, …] };
  # ids outside the caller's own tasks are silently skipped by the `user.tasks` scope.
  def self.reorder_board!(user, days)
    transaction do
      days.each do |key, ids|
        date = key == "unscheduled" ? nil : Date.iso8601(key)
        ids.each_with_index { |id, index| user.tasks.where(id: id).update_all(scheduled_on: date, position: index) }
      end
    end
  end

  def toggle_done!
    update!(status: status == "done" ? "pending" : "done", completed_at: status == "done" ? nil : Time.current)
  end

  def add_subtask!(text)
    update!(subtasks: subtasks + [ { "text" => text, "done" => false } ])
  end

  def toggle_subtask!(index)
    return unless subtasks[index]

    updated = subtasks.dup
    updated[index] = updated[index].merge("done" => !updated[index]["done"])
    update!(subtasks: updated)
  end

  def remove_subtask!(index)
    update!(subtasks: subtasks.each_with_index.reject { |_item, i| i == index }.map(&:first))
  end

  # Soft delete: hidden from the planner immediately, but kept around so
  # "Undo" can bring it straight back without losing subtasks or position.
  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  private
    def assign_position
      self.position = (user&.tasks&.where(scheduled_on: scheduled_on)&.maximum(:position) || -1) + 1
    end

    def inherit_subject_from_topic
      self.subject_id ||= topic&.subject_id
    end

    # A time only makes sense alongside a day; dropping a card into
    # Unscheduled clears any time it had.
    def align_starts_at_with_scheduled_on
      self.starts_at = nil if scheduled_on.nil?
    end

    def topic_belongs_to_user
      errors.add(:topic, "must belong to you") if topic && user && topic.user_id != user_id
    end

    def subject_belongs_to_user
      errors.add(:subject, "must belong to you") if subject && user && subject.user_id != user_id
    end
end
