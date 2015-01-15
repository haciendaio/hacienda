module Hacienda
  module ExecutionTimeLogger

    def log_execution_time_of(thing)
      if (block_given?)
        start_time = Time.now
        begin
          yield
        ensure
          end_time = Time.now
          @log.info("Logging Execution Time: #{thing} ended at #{end_time} and took #{end_time - start_time} seconds.")
        end
      end
    end
  end
end