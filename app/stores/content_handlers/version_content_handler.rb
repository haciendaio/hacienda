require_relative 'content_handler'

module Hacienda

  class VersionContentHandler < ContentHandler

    def initialize(content_digest, file_path_provider)
      @content_digest = content_digest
      @file_path_provider = file_path_provider
    end

    protected

    def do_process(data, query)
      version = version(query)
      data[:version] = version
      data[:versions] = {draft: version, public: version(query, :public)}
    end

    def handles?(query)
      query.state == :draft
    end

    private

    def version(query, state = :draft)
      if state == :public
        json_path = @file_path_provider.public_json_path_for(query.id, query.type, query.locale)
        html_path = @file_path_provider.public_html_path_for(query.id, query.type, query.locale)
      else
        json_path = @file_path_provider.draft_json_path_for(query.id, query.type, query.locale)
        html_path = @file_path_provider.draft_html_path_for(query.id, query.type, query.locale)
      end
      @content_digest.item_version(json_path, html_path)
    end

  end

end