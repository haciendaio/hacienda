require_relative '../utilities/log'
require_relative '../exceptions/raised_exception'

module Hacienda

  module Errors

    class RequestErrorHandler

      def initialize(settings, app, log = Log.new(settings))
        @log = log
        @app = app
      end

      def handle(error)

        if error.is_a? RaisedException
          @log.error(error.message, error) if error.log_error?
          respond_with error.status_code
        else
          @log.error('Request failed, exception caught', error)
          respond_with 500
        end

      end

      private

      def respond_with(status_code)
        @app.status status_code
        @app.halt status_code
      end
    end
  end
end