module Hacienda
  class ContentQuery

    attr_reader :state, :locale, :type, :id, :result_type

    def initialize(state, locale, type, id, result_type = :single)
      @state = state
      @type = type
      @id = id
      @locale = locale
      @result_type = result_type
    end

  end
end
