module Api
  module V1
    class SleepSessionsController < BaseController
      include BatchUpload

      def create
        upsert_batch(SleepSession)
      end
    end
  end
end
