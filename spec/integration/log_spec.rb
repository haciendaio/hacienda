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
      
      before do
        Log.clear_context
      end

      context 'using a logging context' do

        describe '#context' do
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

          it 'should allow specific context information to be set that will exist throughout request' do
            Log.context(some_key: 'snafu')
            Log.context(other_key: 'fooboo')
            some_method_that_will_log('log me')

            expect(log_file).to include '(some_key: snafu, other_key: fooboo) log me'
          end

          it 'should format multiple context items simply' do
            Log.context(doing: 'foobar', id: 'yahoo') do
              some_method_that_will_log('some log')
            end

            expect(log_file).to include '(doing: foobar, id: yahoo) some log'
          end

          it 'should provide information from nested contexts' do
            Log.context(outer: 'foo') do
              Log.context(inner: 'bah') do
                some_method_that_will_log('a line')
              end
            end

            expect(log_file).to include '(outer: foo, inner: bah) a line'
          end

          it 'should provide outer context information after exiting nested contexts' do
            Log.context(outer: 'foo') do
              Log.context(inner: 'bah') do
                # inner
              end
              some_method_that_will_log('after inner but in outer')
            end

            expect(log_file).to include '(outer: foo) after inner but in outer'
          end
          
        end

        describe '#clear_context' do
          it 'should clear info in current context' do
            Log.context(foo: 'bar') 
            Log.clear_context
            
            some_method_that_will_log('boooo!')
            
            expect(log_file).to_not include 'foo: bar'
            expect(log_file).to include 'boo'
          end
          
          it 'should clear outer context info' do
            Log.context(foo: 'bah') do
              Log.context(sna: 'fu') do
                Log.clear_context
              end
              some_method_that_will_log('go go go')
            end
            expect(log_file).to_not include 'sna: fu'
            expect(log_file).to include 'foo: bah'
            expect(log_file).to include 'go go go'
          end
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

