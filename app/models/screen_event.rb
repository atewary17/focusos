# Screen on/off and unlocks; unlocks count as pickups.
class ScreenEvent < ApplicationRecord
  include CollectedData

  KINDS = %w[screen_on screen_off unlock].freeze
  UPSERT_KEY = %i[device_id kind occurred_at].freeze
  UPLOAD_ATTRIBUTES = %i[kind occurred_at].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :occurred_at, presence: true
  validates_not_in_future :occurred_at
end
