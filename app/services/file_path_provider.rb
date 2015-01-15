module Hacienda

  class FilePathProvider

    def public_json_path_for(id, type, locale = 'en')
      "public/#{locale}/#{type}/#{id}.json"
    end

    def draft_json_path_for(id, type, locale='en')
      "draft/#{locale}/#{type}/#{id}.json"
    end

    def public_html_path_for(id, type, locale = 'en')
      "public/#{locale}/#{type}/#{id}-content-body.html"
    end

    def draft_html_path_for(id, type, locale='en')
      "draft/#{locale}/#{type}/#{id}-content-body.html"
    end

    def public_path_for(resource, type, locale='en')
      "public/#{locale}/#{type}/#{resource}"
    end

    def draft_path_for(resource, type, locale='en')
      "draft/#{locale}/#{type}/#{resource}"
    end

    def metadata_path_for(id, type)
      "metadata/#{type}/#{id}.json"
    end

  end
end