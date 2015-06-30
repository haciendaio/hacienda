module SemVer

  def SemVer.from_raw_git_describe(git_version)
    git_version.sub(/(.*)-(\d*)-(.*)/, '\\1.\\3')
  end

  def SemVer.version_from_git
    from_raw_git_describe `git describe --tags origin/master`
  end
end
