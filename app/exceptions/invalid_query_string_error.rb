require_relative 'raised_exception'

module Hacienda
  module Errors

    class InvalidQueryStringError < RaisedException

      def initialize(message=nil)
        error_message = message.nil? ? '' : " - #{message}"
        super(400, "Invalid query string#{error_message}", true)
      end

    end

  end
end
