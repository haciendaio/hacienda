require_relative 'raised_exception'

module Hacienda
  module Errors

    class UnprocessableEntityError < RaisedException

      def initialize(message)
        super(422, message, true)
      end

    end

  end
end