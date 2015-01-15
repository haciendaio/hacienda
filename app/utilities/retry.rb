module Hacienda
  module Retry

    def retry_for_a_number_of_attempts(maximum_attempts, exception_to_retry_for = Exception)
      ensure_log_exists

      number_of_attempts = 0
      begin
        number_of_attempts += 1
        yield
      rescue exception_to_retry_for => e
        @log.info "Retry: Attempt number #{number_of_attempts}/#{maximum_attempts} failed.", e

        if (number_of_attempts < maximum_attempts)
          retry
        else
          raise
        end

      end

    end

    private

    def ensure_log_exists
      raise '@log is nil in Retry host class' if @log.nil?
    end

  end
end