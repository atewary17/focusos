# Shared create action for the collector's upload endpoints: validates every
# item, then upserts all of them, or saves nothing if any item is invalid.
module BatchUpload
  extend ActiveSupport::Concern

  MAX_ITEMS = 1000

  included do
    before_action :require_device
  end

  private
    def upsert_batch(model)
      if Array(params[:items]).size > MAX_ITEMS
        return render_error("validation_failed", "Send at most #{MAX_ITEMS} items per request.", status: 422)
      end

      records = params.expect(items: [ model::UPLOAD_ATTRIBUTES ]).map do |item|
        model.new(item.to_h.merge(user: Current.user, device: Current.device))
      end

      # Items older than the retention window would be deleted within the hour,
      # so they are skipped (and count as accepted) instead of stored.
      fresh = records.each_with_index.reject { |record, _index| DataRetention.stale?(record) }

      invalid = fresh.filter_map do |record, index|
        { index: index, errors: record.errors.full_messages } if record.invalid?
      end
      if invalid.any?
        return render_error("validation_failed", "#{invalid.size} item(s) are invalid; nothing was saved.",
                            status: 422, details: invalid)
      end

      # Postgres rejects an upsert that touches the same row twice, so keep the
      # last item for each key.
      rows = fresh.map(&:first).index_by(&:upsert_key).values.map(&:upsert_row)
      model.transaction { model.upsert_all(rows, unique_by: model::UPSERT_KEY) } if rows.any?

      render json: { upserted: rows.size, skipped: records.size - fresh.size }
    end
end
