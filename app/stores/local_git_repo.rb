require_relative '../../app/utilities/execution_time_logger'
require_relative '../../app/utilities/shell_executor'
require_relative '../../app/utilities/log'

module Hacienda
  class LocalGitRepo
    include ExecutionTimeLogger

    def initialize(data_dir, settings, executor=ShellExecutor.new, log=Log.new(settings), file_obj=File)
      @data_dir = data_dir
      @executor = executor
      @log = log
      @file_obj = file_obj
    end

    def path
      @data_dir
    end

    def pull_latest_content
      status = @executor.run('git status', in: @data_dir)
      @log.debug(status)

      @executor.run('git checkout master', in: @data_dir) unless status.include? 'On branch master'

      if @file_obj.exists? "#{@data_dir}/refs/heads/master.lock"
        @log.info('The master is locked due to an existing pull so not attempting to pull again')
      else
        Thread.exclusive do
          log_execution_time_of "Pulling into #{@data_dir}" do
            output = @executor.run(git_pull_command, in: @data_dir)
            @log.info("Succeeded with output:\n#{output}")
            output
          end
        end

      end
    end

    private

    def git_pull_command
      os = @executor.run('uname')
      linux_git_pull = 'flock -sx . -c "git pull --verbose"'
      mac_git_pull = 'git pull --verbose'
      os.include?('Linux') ? linux_git_pull : mac_git_pull
    end
  end
end