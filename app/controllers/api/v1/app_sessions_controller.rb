module Api
  module V1
    class AppSessionsController < BaseController
      include BatchUpload

      def create
        upsert_batch(AppSession)
      end
    end
  end
end
