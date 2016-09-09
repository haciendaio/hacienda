require_relative 'content'

module Hacienda
  class ContentFactory

    def instance(id, content_data, type:, locale:)
      Content.build(id, content_data, type: type, locale: locale)
    end
  end
end
