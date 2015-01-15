require_relative '../unit_helper'
require_relative '../../../app/utilities/shell_executor'

module Hacienda
  module Test

    describe 'Shell executor' do
      SILENCE_STDERR = ' 2> /dev/null'

      it 'should run shell commands' do
        ShellExecutor.new.run('ls').should include 'Rakefile'
      end

      it 'should object to unknown option' do
        expect {
          ShellExecutor.new.run('ls', blarf: 'blah')
        }.to(raise_exception) { |e|
          e.message.should include 'blarf'
        }
      end

      it 'should raise an exception for a non-existent shell command' do
        expect {
          ShellExecutor.new.run('I will break hideously')
        }.to raise_exception
      end

      it 'should raise an exception when shell command fails (i.e. non-zero exit code)' do
        expect {
          ShellExecutor.new.run('ls non_existent_file' + SILENCE_STDERR)
        }.to raise_exception
      end

      it 'should include the output of a failed command in the raised exception' do
        expect {
          ShellExecutor.new.run('ls non_existent_file' + SILENCE_STDERR)
        }.to raise_error { |error|
               error.message.should include 'non_existent_file'
             }
      end

      it 'should run command in specified directory' do
        Dir.should_receive(:chdir).with('spec/unit')
        ShellExecutor.new.run("ls #{__FILE__}", in: 'spec/unit')
      end

    end
  end
end
