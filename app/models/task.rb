# A backlog card. Lanes are the board columns; dragging a card into "done"
# completes it, dragging it back out reopens it.
class Task < ApplicationRecord
  LANES = %w[backlog next today done].freeze
  STATUSES = %w[pending done skipped].freeze
  ENERGIES = %w[high low].freeze

  belongs_to :user
  belongs_to :topic, optional: true
  belongs_to :subject, optional: true
  belongs_to :carried_from, class_name: "Task", optional: true

  before_validation :assign_position, on: :create
  before_validation :inherit_subject_from_topic
  before_save :sync_status_with_lane

  validates :title, presence: true, length: { maximum: 200 }
  validates :notes, length: { maximum: 2000 }
  validates :lane, inclusion: { in: LANES }
  validates :status, inclusion: { in: STATUSES }
  validates :energy, inclusion: { in: ENERGIES }, allow_nil: true
  validates :priority, inclusion: { in: 1..3 }, allow_nil: true
  validates :estimate_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validate :topic_belongs_to_user
  validate :subject_belongs_to_user

  scope :in_lane, ->(lane) { where(lane: lane).order(:position) }

  # Moves every card into the given lane and position, in one transaction.
  # `lanes` is { "backlog" => [id, id, …], "next" => [...], … }; ids outside
  # the caller's own tasks are silently skipped by the `user.tasks` scope.
  def self.reorder_board!(user, lanes)
    transaction do
      lanes.each do |lane, ids|
        ids.each_with_index { |id, index| user.tasks.where(id: id).update_all(lane: lane, position: index) }
      end
    end
  end

  private
    def assign_position
      self.position = (user&.tasks&.where(lane: lane)&.maximum(:position) || -1) + 1
    end

    def inherit_subject_from_topic
      self.subject_id ||= topic&.subject_id
    end

    def sync_status_with_lane
      if lane_changed? && lane == "done"
        self.status = "done"
        self.completed_at ||= Time.current
      elsif lane_changed? && status == "done"
        self.status = "pending"
        self.completed_at = nil
      end
    end

    def topic_belongs_to_user
      errors.add(:topic, "must belong to you") if topic && user && topic.user_id != user_id
    end

    def subject_belongs_to_user
      errors.add(:subject, "must belong to you") if subject && user && subject.user_id != user_id
    end
end
