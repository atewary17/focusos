# Per-app foreground time for one local day on one device (from UsageStatsManager).
class AppUsageDay < ApplicationRecord
  include CollectedData

  UPSERT_KEY = %i[device_id package_name date].freeze
  UPLOAD_ATTRIBUTES = %i[date package_name app_label foreground_seconds launches first_used_at last_used_at].freeze

  validates :date, :package_name, presence: true
  validates :package_name, :app_label, length: { maximum: 255 }
  validates :foreground_seconds, numericality: { only_integer: true, in: 0..1.day.to_i }
  validates :launches, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates_not_in_future :first_used_at, :last_used_at
  validate { errors.add(:date, "is in the future") if date && date > Date.current + 1 }
end
