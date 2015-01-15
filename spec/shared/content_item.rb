require 'json'

module Hacienda
  module Test

    class ContentItem < Hash
      def initialize
        with  id: 'an_identifier',
                locale: 'en',
                type: 'a_type'
      end

      def with(values = {})
        merge! values
        self
      end

      def to_hash
        self
      end

      def locale
        fetch :locale
      end

      def type
        fetch :type
      end

      def id
        fetch :id
      end

    end

  end
end
