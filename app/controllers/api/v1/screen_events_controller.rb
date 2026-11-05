module Api
  module V1
    class ScreenEventsController < BaseController
      include BatchUpload

      def create
        upsert_batch(ScreenEvent)
      end
    end
  end
end
