require_relative '../unit_helper'
require_relative '../../../app/utilities/retry'

module Hacienda
  module Test

    describe 'Retry' do

      let(:log) { double('log', info: nil, error: nil) }
      let(:error) { StandardError.new('Error') }
      let(:test_retries) { TestRetries.new(log) }

      context 'for a number of attempts' do

        it 'should retry an operation for the maximum number of attempts' do
          test_retries.do_for_a_number_of_attempts(3) {
            raise error
          } rescue Exception

          expect(test_retries.number_of_attempts).to eq 3
        end

        it 'should log each retry attempt' do
          test_retries.do_for_a_number_of_attempts(3) {
            raise error
          } rescue Exception

          expect(log).to have_received(:info).with('Retry: Attempt number 1/3 failed.', error)
          expect(log).to have_received(:info).with('Retry: Attempt number 2/3 failed.', error)
          expect(log).to have_received(:info).with('Retry: Attempt number 3/3 failed.', error)
        end

        it 'should not retry if expected error does not match' do
          different_error = DifferentError.new

          expect {
            test_retries.do_for_a_number_of_attempts(3, StandardError) { raise different_error }
          }.to raise_error(different_error)

          expect(test_retries.number_of_attempts).to eq 1
        end

        it 'should raise an error after final attempt fails' do
          expect {
            test_retries.do_for_a_number_of_attempts(3) { raise error }
          }.to raise_error (error)
        end

        it 'should throw an error if no log is available' do
          expect {
            TestRetries.new(nil).do_for_a_number_of_attempts(3)
          }.to raise_error { |error|
                 error.message.should include '@log'
                 error.message.should include 'nil'
               }
        end

      end

    end

    class TestRetries
      include Retry

      attr_reader :number_of_attempts

      def initialize(log)
        @log = log
        @number_of_attempts = 0
      end

      def do_for_a_number_of_attempts(attempts, exception_to_retry_for = Exception, &something)
        retry_for_a_number_of_attempts(attempts, exception_to_retry_for) do
          @number_of_attempts += 1
          something.call
        end
      end

    end

    class DifferentError < Exception
    end
  end
end
