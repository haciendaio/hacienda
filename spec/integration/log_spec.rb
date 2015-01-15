require_relative '../integration_helper'
require_relative '../../app/utilities/log'

module Hacienda
  module Test

    describe Log do

      let(:settings) {double('settings', log_path: log_filepath)}
      let(:log) { Log.new(settings) }

      before :each do
        FileUtils.rm_f log_filepath
      end

      context 'using a logging context' do

        it 'should report the context if it is set, even within a method' do
          Log.context(doing: 'foobar') do
            some_method_that_will_log('some info')
          end

          expect(log_file).to include '(doing: foobar) some info'
        end

        it 'should return the context back to normal after the block' do
          Log.context(doing: 'foobar') {}

          some_method_that_will_log('some info')

          expect(log_file).to include 'some info'
          expect(log_file).to_not include '(doing: foobar)'
        end

        it 'should return the context back to normal even if an error is raised' do
          expect {
            Log.context(doing: 'foobar') do
              raise 'an error occurred inside the log context'
            end
          }.to raise_error

          some_method_that_will_log('some info')

          expect(log_file).to include 'some info'
          expect(log_file).to_not include '(doing: foobar)'
        end

        it 'should format multiple context items simply' do
          Log.context(doing: 'foobar', id: 'yahoo') do
            some_method_that_will_log('some log')
          end

          expect(log_file).to include '(doing: foobar, id: yahoo) some log'
        end

        private

        def log_file
          File.read log_filepath
        end

        def log_filepath
          './build/log_spec.log'
        end

        def some_method_that_will_log(message)
          log.info(message)
        end


      end

    end
  end
end

