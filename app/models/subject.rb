# A subject groups topics and tasks for the backlog board (e.g. "Economics").
class Subject < ApplicationRecord
  belongs_to :user
  has_many :topics, -> { order(:position) }, dependent: :destroy
  has_many :tasks, dependent: :nullify
  has_many :recurring_tasks, dependent: :nullify

  before_validation :assign_position, on: :create

  validates :name, presence: true, length: { maximum: 60 }
  validates :color, presence: true, format: { with: /\A#[0-9a-f]{6}\z/i, message: "must be a hex color like #0f766e" }
  validates :weekly_target_minutes, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(archived_at: nil).order(:position) }

  def archived? = archived_at.present?

  private
    def assign_position
      self.position = (user.subjects.maximum(:position) || -1) + 1
    end
end
