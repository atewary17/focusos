# One night or nap from Health Connect, with its stages as [{ stage, start, end }].
class SleepSession < ApplicationRecord
  include CollectedData

  STAGES = %w[awake sleeping out_of_bed light deep rem awake_in_bed unknown].freeze
  UPSERT_KEY = %i[user_id source_package started_at].freeze
  UPLOAD_ATTRIBUTES = [ :started_at, :ended_at, :source_package, :external_id, { stages: [ [ :stage, :start, :end ] ] } ].freeze

  validates :started_at, :ended_at, :source_package, presence: true
  validates :source_package, :external_id, length: { maximum: 255 }
  validates_not_before :ended_at, :started_at
  validates_not_in_future :started_at, :ended_at
  validate :stages_are_well_formed

  def duration_minutes
    ((ended_at - started_at) / 60).round
  end

  private
    def stages_are_well_formed
      unless stages.is_a?(Array) && stages.all? { |s| s.is_a?(Hash) && STAGES.include?(s["stage"]) && s["start"].present? && s["end"].present? }
        errors.add(:stages, "must be a list of { stage, start, end } with a known stage")
      end
    end
end
