require 'json'

module Hacienda
  module Test

    class StatusResponse
      def initialize(page)
        @page = page
      end

      def status
        JSON.parse(@page)['status']
      end
    end
  end
end
