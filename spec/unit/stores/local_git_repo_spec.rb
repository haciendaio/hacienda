require_relative '../unit_helper'
require_relative '../../../spec/fake_settings'
require_relative '../../../app/stores/local_git_repo'

module Hacienda
  module Test

    describe 'Local git repo' do
      include FakeSettings

      before :each do
        @executor = double('executor')
        @executor.stub(:run).with('git status', anything).and_return("# On branch master")
        @executor.stub(:run).with('git pull --verbose', anything)
        @executor.stub(:run).with('uname').and_return('Darwin\n')
      end

      let(:log) {double('log', info: nil, debug: nil)}
      let(:file_mock) {double('File')}

      it 'should pull from git command line using flock on linux' do
        file_mock = double('File').as_null_object
        file_mock.stub(:exists?).and_return(false)

        @executor.stub(:run).with('uname').and_return('Linux\n')
        @executor.should_receive(:run).with('flock -sx . -c "git pull --verbose"', {in: '/the-data-dir'})

        local_git_repo = LocalGitRepo.new('/the-data-dir', fake_settings, @executor, log, file_mock)

        local_git_repo.pull_latest_content
      end

      it 'should pull from git command line without flock on osx' do
        file_mock = double('File').as_null_object
        file_mock.stub(:exists?).and_return(false)

        @executor.stub(:run).with('uname').and_return('Darwin\n')
        @executor.should_receive(:run).with('git pull --verbose', {in: '/the-data-dir'})

        local_git_repo = LocalGitRepo.new('/the-data-dir', fake_settings, @executor, log, file_mock)

        local_git_repo.pull_latest_content
      end

      it 'should log the execution time of pulling from git' do
        file_mock = double('File').as_null_object
        file_mock.stub(:exists?).and_return(false)
        @executor.stub(:run => 'done pulling')

        local_git_repo = LocalGitRepo.new('/another-data-dir', fake_settings, @executor, log, file_mock)

        local_git_repo.pull_latest_content

        log.should have_received(:info).with(start_with('Logging Execution Time'))
      end

      it 'should log and not pull when master.lock exists/ ie. another pull is in progress' do
        file_mock = double('File')
        file_mock.stub(:exists?).with('/data-dir/refs/heads/master.lock').and_return(true)

        log.should_receive(:info).with('The master is locked due to an existing pull so not attempting to pull again')
        @executor.should_not_receive(:run).with('git pull --verbose', anything)

        local_git_repo = LocalGitRepo.new('/data-dir', fake_settings, @executor, log, file_mock)
        local_git_repo.pull_latest_content

      end

      context 'ensuring working tree on correct branch' do

        it 'should switch to master before pulling when currently on another branch' do
          file_mock.stub(:exists?).and_return(false)

          @executor.stub(:run).with('git checkout master', anything).and_return("Switched to branch 'master'")
          @executor.stub(:run).with('git status', in: '/data-dir').and_return("# On branch public")

          @executor.should receive(:run).ordered.with('git checkout master', in: '/data-dir')
          @executor.should receive(:run).ordered.with('git pull --verbose', in: '/data-dir')

          local_git_repo = LocalGitRepo.new('/data-dir', fake_settings, @executor, log, file_mock)
          local_git_repo.pull_latest_content
        end

        it 'should leave working tree on master' do
          file_mock.stub(:exists?).and_return(false)

          @executor.stub(:run).with('git status', anything).and_return("# On branch master")

          @executor.should_not receive(:run).with('git checkout master', '/data-dir')

          local_git_repo = LocalGitRepo.new('/data-dir', fake_settings, @executor, log, file_mock)
          local_git_repo.pull_latest_content
        end
      end
    end
  end
end

