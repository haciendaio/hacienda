module Hacienda
  class RaisedException < StandardError

    attr_reader :status_code

    def initialize(status_code, message, log_error)
      @status_code = status_code
      @log_error = log_error
      super(message)
    end

    def log_error?
      @log_error
    end

  end

end