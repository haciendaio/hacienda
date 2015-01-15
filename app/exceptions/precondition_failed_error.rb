require_relative 'raised_exception'

module Hacienda
  module Errors

    class PreconditionFailedError < RaisedException

      def initialize
        super(412, 'Precondition failed', false)
      end

    end

  end
end
