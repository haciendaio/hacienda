require_relative '../unit_helper'
require_relative '../../../app/web/request_error_handler'
require_relative '../../../app/utilities/log'
require_relative '../sinatra_stub_lite'
require_relative '../../../app/exceptions/file_not_found_error'
require_relative '../../../app/exceptions/page_not_found_error'
require_relative '../../../app/exceptions/precondition_failed_error'
require_relative '../../../app/exceptions/unprocessable_entity_error'
require_relative '../../../app/exceptions/raised_exception'
require_relative '../../../spec/fake_settings'

module Hacienda
  module Test

    describe 'website request error handler' do

      include FakeSettings

      before :each do
        @log = double('log', error: nil)
        @sinatra_stub = SinatraStubLite.new
        @error_handler = Errors::RequestErrorHandler.new(fake_settings, @sinatra_stub, @log)
      end

      it 'should response with the exceptions status code when it is a raised exception' do
        @error_handler.handle(TestRaisedException.new(666, 'Devil errors', true))
        expect(@sinatra_stub.status_value).to eq(666)
        expect(@sinatra_stub.halted_with).to eq(666)
      end

      it 'should log error if logging is enabled in exception' do
        error = TestRaisedException.new(666, 'Devil errors', true)
        @error_handler.handle(error)
        expect(@log).to have_received(:error).with('Devil errors', error)
      end

      it 'should respond with 500 and log the error when it is not a raised exception' do
        error = Exception.new
        @error_handler.handle(error)
        expect(@sinatra_stub.status_value).to eq(500)
        expect(@sinatra_stub.halted_with).to eq(500)
        expect(@log).to have_received(:error).with('Request failed, exception caught', error)
      end

      class TestRaisedException < RaisedException

        def initialize(status, message, logged)
          super(status, message, logged)
        end

      end

    end
  end
end
