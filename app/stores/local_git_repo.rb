require_relative '../../app/utilities/execution_time_logger'
require_relative '../../app/utilities/shell_executor'
require_relative '../../app/utilities/log'
require_relative '../../app/exceptions/not_found_exception'
require_relative '../../app/utilities/rugged_wrapper'

require 'rugged'

module Hacienda
  class LocalGitRepo
    MUTEX = Thread::Mutex.new
    private_constant :MUTEX

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
      @log.debug('NB This status is executed outside of single-process locking, so may represent intermediate state of ' +
                     "ongoing pull:\n #{status}")

      @executor.run('git checkout master', in: @data_dir) unless status.include? 'On branch master'

      if @file_obj.exists? "#{@data_dir}/refs/heads/master.lock"
        @log.info('The master is locked due to an existing pull so not attempting to pull again')
      else
        MUTEX.synchronize do
          log_execution_time_of "Pulling into #{@data_dir}" do
            output = @executor.run(git_pull_command, in: @data_dir)
            @log.info("Succeeded with output:\n#{output}")
            output
          end
        end

      end
    end

    def get_version_for_file_at(file_path, changes_in_the_past)
      blob = RuggedWrapperFactory.new.get_repo(@data_dir).get_version_in_past(file_path, changes_in_the_past)
      raise FileNotFoundError.new(file_path) unless blob
      blob.text
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
