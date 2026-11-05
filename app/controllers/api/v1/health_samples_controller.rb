module Api
  module V1
    class HealthSamplesController < BaseController
      include BatchUpload

      def create
        upsert_batch(HealthSample)
      end
    end
  end
end
