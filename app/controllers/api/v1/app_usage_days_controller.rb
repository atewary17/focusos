module Api
  module V1
    class AppUsageDaysController < BaseController
      include BatchUpload

      def create
        upsert_batch(AppUsageDay)
      end
    end
  end
end
