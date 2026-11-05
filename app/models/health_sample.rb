# One Health Connect reading (heart rate, SpO₂, steps interval, HRV, resting HR).
class HealthSample < ApplicationRecord
  include CollectedData

  RANGES = {
    "heart_rate" => 25..250,
    "resting_hr" => 25..250,
    "spo2" => 70..100,
    "steps" => 0..100_000,
    "hrv_rmssd" => 0..500
  }.freeze
  KINDS = RANGES.keys.freeze
  UPSERT_KEY = %i[user_id kind recorded_at source_package].freeze
  UPLOAD_ATTRIBUTES = %i[kind recorded_at end_at value unit source_package external_id].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :recorded_at, :value, :unit, :source_package, presence: true
  validates :unit, :source_package, :external_id, length: { maximum: 255 }
  validates_not_before :end_at, :recorded_at
  validates_not_in_future :recorded_at, :end_at
  validate do
    range = RANGES[kind]
    errors.add(:value, "must be between #{range.min} and #{range.max} for #{kind}") if range && value && !range.cover?(value)
  end
end
