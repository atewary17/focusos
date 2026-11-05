# Rows uploaded by a device through the ingest API. Uploads are validated as
# models, then written with `upsert_all` on UPSERT_KEY so re-sending is safe.
module CollectedData
  extend ActiveSupport::Concern

  FUTURE_TOLERANCE = 5.minutes

  included do
    belongs_to :user
    belongs_to :device
  end

  class_methods do
    def validates_not_in_future(*attributes)
      validate do
        attributes.each do |attribute|
          value = public_send(attribute)
          errors.add(attribute, "is in the future") if value && value > Time.current + FUTURE_TOLERANCE
        end
      end
    end

    def validates_not_before(later, earlier)
      validate do
        a, b = public_send(later), public_send(earlier)
        errors.add(later, "must not be before #{earlier}") if a && b && a < b
      end
    end
  end

  def upsert_row
    attributes.except("id", "created_at", "updated_at")
  end

  def upsert_key
    upsert_row.values_at(*self.class::UPSERT_KEY.map(&:to_s))
  end
end
