# One "Are you focused?" prompt sent by the phone and its answer.
class CheckIn < ApplicationRecord
  include CollectedData

  ANSWERS = %w[focused not_focused no_answer].freeze
  UPSERT_KEY = %i[device_id asked_at].freeze
  UPLOAD_ATTRIBUTES = %i[asked_at answer answered_at source].freeze

  validates :asked_at, presence: true
  validates :answer, inclusion: { in: ANSWERS }
  validates :answered_at, presence: true, unless: -> { answer == "no_answer" }
  validates :source, length: { maximum: 255 }
  validates_not_before :answered_at, :asked_at
  validates_not_in_future :asked_at, :answered_at
end
