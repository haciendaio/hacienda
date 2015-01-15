require 'logger'

module Hacienda
  class Log

    TIME_PATTERN = '%F %T'

    def self.context(info={})
      begin
        Thread.current[:logging_context] = info
        return_value = yield
      ensure
        Thread.current[:logging_context] = nil
      end
      return_value
    end

    def self.context_info
      Thread.current[:logging_context]
    end

    def initialize (settings, logger = Logger.new(settings.log_path), clock = Time)
      @logger = logger
      @clock = clock
    end

    def error(message, error = nil)
      @logger.error format_message(error, message)
    end

    def info(message, error = nil)
      @logger.info format_message(error, message)
    end

    def warn(message, error = nil)
      @logger.warn format_message(error, message)
    end

    def debug(message, error=nil)
      @logger.debug format_message(error, message)
    end

    def add_timestamp_to_message(formatted_message)
      "[#{@clock.now.strftime(TIME_PATTERN)}]: #{formatted_message}"
    end


    private

    def format_message(error, message)
      if error.nil?
        formatted_message = with_context(message)
      else
        formatted_message = with_stacktrace(error, with_context(message))
      end
      add_timestamp_to_message(formatted_message)
    end

    def with_context(message)
      if Log.context_info.nil?
        return message
      end
      "(#{formatted_context()}) #{message}"
    end

    def formatted_context
      Log.context_info.collect do |k, v|
        "#{k}: #{v}"
      end.join(', ')
    end

    def with_stacktrace(error, message)
      "#{message}: Caught #{error.to_s}" + one_per_line_with_indent(error.backtrace)
    end

    def one_per_line_with_indent(stacktrace)
      stacktrace.map { |msg| "\n    #{msg}" }.join
    end
  end
end