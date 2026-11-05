# Hourly, so each user's data is trimmed soon after midnight in their own time zone.
class PurgeStaleDataJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      deleted = DataRetention.purge!(user).select { |_model, count| count.positive? }
      Rails.logger.info("PurgeStaleDataJob user=#{user.id} deleted=#{deleted}") if deleted.any?
    end
  end
end
