require_relative '../../app/utilities/execution_time_logger'
require_relative '../../app/utilities/shell_executor'
require_relative '../../app/utilities/log'
require_relative '../../app/exceptions/not_found_exception'

require 'rugged'

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

    def get_version_for_file_at(file_path, changes_in_the_past)
      blob = history_for_file(file_path, changes_in_the_past)
      raise FileNotFoundError.new(file_path) unless blob
      blob.text
    end

    def history_for_file(file_path, changes_in_the_past)
      repo = Rugged::Repository.new(@data_dir)
      walker = Rugged::Walker.new(repo)
      walker.push(repo.last_commit)

      last_blob = repo.blob_at(repo.last_commit.oid, file_path)
      current_blob_id = last_blob.oid

      walker.each do |commit|
        blob = repo.blob_at(commit.oid, file_path)
        blob_id = (blob ? blob.oid : 0)

        if current_blob_id != blob_id
          current_blob_id = blob_id
          last_blob = blob
          changes_in_the_past -= 1
        end
        break if (changes_in_the_past == 0)
        break unless last_blob
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