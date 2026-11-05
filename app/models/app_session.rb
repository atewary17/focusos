# One continuous stretch of an app in the foreground.
class AppSession < ApplicationRecord
  include CollectedData

  UPSERT_KEY = %i[device_id package_name started_at].freeze
  UPLOAD_ATTRIBUTES = %i[package_name started_at ended_at].freeze

  before_validation { self.duration_seconds = (ended_at - started_at).to_i if started_at && ended_at }

  validates :package_name, :started_at, :ended_at, presence: true
  validates :package_name, length: { maximum: 255 }
  validates :duration_seconds, numericality: { in: 0..1.day.to_i }, allow_nil: true
  validates_not_before :ended_at, :started_at
  validates_not_in_future :started_at, :ended_at
end
