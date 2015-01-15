module Hacienda
  module GithubSettings
    def is_github_organization_defined?(settings)
      settings.respond_to? :github_organization
    end

    def repo_qualified_name(settings)
      is_github_organization_defined?(settings) ? "#{settings.github_organization}/#{settings.content_repo}" : "#{settings.github_user}/#{settings.content_repo}"
    end
  end
end