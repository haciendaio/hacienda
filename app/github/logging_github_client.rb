require_relative '../utilities/execution_time_logger'

module Hacienda
  class LoggingGithubClient
    include ExecutionTimeLogger

    def initialize(client, log)
      @client = client
      @log = log
    end

    def method_missing(method, *args)
      if @client.respond_to?(method)
        log_execution_time_of "github_client##{method}", :debug do
          @client.send method, *args
        end
      else
        super
      end
    end
  end
end