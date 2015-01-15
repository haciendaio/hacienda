require_relative '../unit_helper'
require_relative '../../../app/utilities/execution_time_logger'

module Hacienda
  module Test

    describe 'Execution time logger' do

      class LoggerHost
        include ExecutionTimeLogger

        def initialize(log)
          @log = log
        end

      end

      it 'should log the end time of a block' do
        start_time, end_time = Time.mktime(2013, 7, 21, 9, 0, 0), Time.mktime(2013, 7, 21, 9, 0, 12)
        Time.stub(:now).and_return(start_time, end_time)

        log = double('Log', info: nil)

        LoggerHost.new(log).log_execution_time_of 'Test Thing' do
        end

        log.should have_received(:info).with("Logging Execution Time: Test Thing ended at #{end_time} and took 12.0 seconds.")
      end

      it 'should log the end time even when there is an error' do
        start_time, end_time = Time.mktime(2013, 7, 21, 9, 0, 0), Time.mktime(2013, 7, 21, 9, 0, 12)
        Time.stub(:now).and_return(start_time, end_time)

        log = double('Log', info: nil)

        begin
          LoggerHost.new(log).log_execution_time_of 'Test Thing' do
            raise 'An error occurred'
          end
        rescue
        end

        log.should have_received(:info).with("Logging Execution Time: Test Thing ended at #{end_time} and took 12.0 seconds.")
      end

      it 'should not log anything if a block is not supplied' do
        log = double('Log', info: nil)
        LoggerHost.new(log).log_execution_time_of 'Test Thing'
        log.should_not have_received(:info)
      end
    end
  end
end
