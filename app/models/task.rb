# A plan card, usable from two independent views:
#   - the Board (status lanes: pending/doing/done), ordered by board_position
#   - the Calendar (scheduled_on + starts_at), ordered by calendar_position
# A card can be in both at once (e.g. "doing" and scheduled for 2pm) since
# status and scheduling are unrelated axes.
class Task < ApplicationRecord
  STATUSES = %w[pending doing done skipped].freeze
  ENERGIES = %w[high low].freeze

  belongs_to :user
  belongs_to :topic, optional: true
  belongs_to :subject, optional: true
  belongs_to :carried_from, class_name: "Task", optional: true
  belongs_to :recurring_task, optional: true

  before_validation :assign_calendar_position, on: :create
  before_validation :assign_board_position, on: :create
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

  scope :kept, -> { where(deleted_at: nil) }

  # Moves every card into the given status lane and board position, in one
  # transaction. `statuses` is { "pending" | "doing" | "done" => [id, …] }.
  def self.reorder_board!(user, statuses)
    transaction do
      statuses.each do |status, ids|
        ids.each_with_index { |id, index| user.tasks.where(id: id).update_all(status: status, board_position: index) }
      end
    end
  end

  # Moves one card to a specific day and time (or clears scheduling if
  # `date` is nil), keeping it last in that day's calendar order.
  def reschedule!(date, time_of_day = nil)
    new_position = date ? (user.tasks.where(scheduled_on: date).maximum(:calendar_position) || -1) + 1 : 0
    update!(scheduled_on: date, starts_at: date && time_of_day ? Time.zone.local(date.year, date.month, date.day, time_of_day.hour, time_of_day.min) : nil,
            calendar_position: new_position)
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
    def assign_calendar_position
      self.calendar_position = (user&.tasks&.where(scheduled_on: scheduled_on)&.maximum(:calendar_position) || -1) + 1
    end

    def assign_board_position
      self.board_position = (user&.tasks&.where(status: status)&.maximum(:board_position) || -1) + 1
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
