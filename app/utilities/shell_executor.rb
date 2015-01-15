module Hacienda
  class ShellExecutor
    def run(command, options={in: '.'})
      Dir.chdir options[:in] do
        output = `#{command}`
        raise "#{command} failed with exit code #{$?}:\n#{output}" if $? != 0
        output
      end
    end
  end
end