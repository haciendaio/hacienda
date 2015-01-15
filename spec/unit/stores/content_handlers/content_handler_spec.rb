require_relative '../../unit_helper'
require_relative '../../../../app/stores/content_handlers/content_handler'

module Hacienda

  class TestHandler < ContentHandler

    attr_reader :processed

    def initialize
      @processed = false
    end

    protected

    def do_process(data, query)
      @processed = true
    end

  end

  module Test

    describe "Content handler" do

      it 'should assume that handlers apply by default' do
        handler = TestHandler.new

        handler.process!(nil, nil)

        expect(handler.processed).to be_true
      end

      it 'should handle a request if the subclass says so' do
        handler = TestHandler.new
        def handler.handles?(query); true; end

        handler.process!(nil, nil)

        expect(handler.processed).to be_true
      end

      it 'should not handle a request if the subclass says no' do
        handler = TestHandler.new
        def handler.handles?(query); false; end

        handler.process!(nil, nil)

        expect(handler.processed).to be_false
      end
    end

  end
end

