module Api
  module V1
    class CheckInsController < BaseController
      include BatchUpload

      def create
        upsert_batch(CheckIn)
      end
    end
  end
end
